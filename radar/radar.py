#!/usr/bin/env python3
"""radar - in-session feature & new tool discovery.

Usage:
  radar                 Open the interactive review TUI (fzf, or a plain menu fallback)
  radar refresh [--if-stale]
                        Fetch upstream releases and rebuild the cache (run in background
                        by .zshrc at most once per 24h)
  radar list            Print pending items as TSV: id, kind, title, summary
  radar show <id>       Print details for one item
  radar install <id>    Install / upgrade the tool behind an item
  radar dismiss <id>    Hide an item (updates re-appear when a newer release ships)

Environment:
  RADAR_CACHE_DIR       Cache location (default: $XDG_CACHE_HOME/radar or ~/.cache/radar)
  RADAR_WATCHLIST       Tools to track (default: watchlist.json next to this script)
  RADAR_DISCOVER        Curated discovery catalog (default: discover.json next to this script)
  RADAR_FIXTURE_DIR     Read releases/installed versions from fixtures instead of network/brew
  GITHUB_TOKEN/GH_TOKEN Optional, raises GitHub API rate limits (never stored)
"""
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.realpath(__file__))
STALE_AFTER_SECONDS = 24 * 60 * 60
BANNER_MAX_NAMED = 3

_VERSION_RE = re.compile(r"(\d+)(?:\.(\d+))?(?:\.(\d+))?")
_BREAKING_RE = re.compile(r"breaking[ _-]changes?", re.IGNORECASE)


# ---------------------------------------------------------------------------
# Noise filter
# ---------------------------------------------------------------------------

def parse_version(text):
    """Extract a (major, minor, patch) tuple from a tag like 'v1.2.3' or 'tmux-3.5a'."""
    m = _VERSION_RE.search(text or "")
    if not m:
        return None
    return tuple(int(part or 0) for part in m.groups())


def format_version(text):
    v = parse_version(text)
    return ".".join(str(p) for p in v) if v else (text or "?")


_HEADING_RE = re.compile(r"^\s*#{1,6}\s*(.*)$")
_BULLET_RE = re.compile(r"^\s*[-*+]\s+(.*)$")
_FEATURE_HEADING_RE = re.compile(r"feature|highlight|new|added|enhancement|improvement", re.IGNORECASE)
_LINK_RE = re.compile(r"\[([^\]]*)\]\([^)]*\)")
_TRAILING_REF_RE = re.compile(r"\s*(\(#\d+\)|\(\[#\d+\]\)|by @\S+.*|in https?://\S+)\s*$")


def _clean_bullet(text):
    text = _LINK_RE.sub(r"\1", text)
    text = _TRAILING_REF_RE.sub("", text).strip().rstrip(".")
    return text if len(text) <= 100 else text[:97].rstrip() + "..."


def highlights(notes, limit=2):
    """First bullets under a feature-ish heading, falling back to the first bullets anywhere."""
    featured, anywhere, in_feature_section = [], [], False
    for line in (notes or "").splitlines():
        heading = _HEADING_RE.match(line)
        if heading:
            in_feature_section = bool(_FEATURE_HEADING_RE.search(heading.group(1)))
            continue
        bullet = _BULLET_RE.match(line)
        if bullet:
            cleaned = _clean_bullet(bullet.group(1))
            if cleaned:
                (featured if in_feature_section else anywhere).append(cleaned)
    return (featured or anywhere)[:limit]


def classify(installed, latest, notes):
    """Noise filter: 'breaking', 'feature', or None (ignored)."""
    old, new = parse_version(installed), parse_version(latest)
    if new is None or old is None or new <= old:
        return None
    if new[0] > old[0] or _BREAKING_RE.search(notes or ""):
        return "breaking"
    if new[:2] > old[:2] or (_FEATURE_HEADING_RE.search(notes or "") and bool(highlights(notes))):
        return "feature"
    return None


def summarize(why, notes):
    """1-2 sentence 'why this matters for your workflow'."""
    parts = [why.strip()] if why else []
    found = highlights(notes)
    if found:
        parts.append("New: %s." % "; ".join(found))
    return " ".join(parts)


# ---------------------------------------------------------------------------
# Paths & state
# ---------------------------------------------------------------------------

def cache_dir():
    default = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "radar")
    return os.environ.get("RADAR_CACHE_DIR") or default


def cache_path(name):
    return os.path.join(cache_dir(), name)


def read_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except (OSError, ValueError):
        return default


def write_atomic(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = "%s.%d.tmp" % (path, os.getpid())
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


# ---------------------------------------------------------------------------
# Upstream adapters (GitHub releases, Homebrew installed versions)
# ---------------------------------------------------------------------------

def fetch_release(repo):
    fixtures = os.environ.get("RADAR_FIXTURE_DIR")
    if fixtures:
        return read_json(os.path.join(fixtures, "releases", repo.replace("/", "__") + ".json"), None)
    req = urllib.request.Request(
        "https://api.github.com/repos/%s/releases/latest" % repo,
        headers={"Accept": "application/vnd.github+json", "User-Agent": "dotfiles-radar"})
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.load(resp)
    except Exception:
        return None


def installed_versions():
    """Map of brew formula/cask name -> installed version."""
    fixtures = os.environ.get("RADAR_FIXTURE_DIR")
    if fixtures:
        return read_json(os.path.join(fixtures, "installed.json"), {})
    try:
        out = subprocess.run(["brew", "info", "--json=v2", "--installed"],
                             capture_output=True, text=True, timeout=120).stdout
        data = json.loads(out)
    except Exception:
        return {}
    versions = {}
    for f in data.get("formulae", []):
        if f.get("installed"):
            linked = f.get("linked_keg")
            version = linked if linked else f["installed"][-1].get("version", "")
            versions[f["name"]] = version
    for c in data.get("casks", []):
        if c.get("installed"):
            versions[c["token"]] = c["installed"]
    return versions


# ---------------------------------------------------------------------------
# Refresh & banner
# ---------------------------------------------------------------------------

def data_file(env_var, default_name):
    return os.environ.get(env_var) or os.path.join(HERE, default_name)


def upgrade_command(tool):
    if tool.get("upgrade"):
        return tool["upgrade"]
    cask = "--cask " if tool.get("cask") else ""
    return "brew upgrade %s%s" % (cask, tool.get("formula", tool["name"]))


def refresh():
    watchlist = read_json(data_file("RADAR_WATCHLIST", "watchlist.json"), [])
    installed = installed_versions()
    if not installed and not os.environ.get("RADAR_FIXTURE_DIR"):
        return
    previous = {u["name"]: u for u in read_json(cache_path("updates.json"), [])}
    updates = []
    for tool in watchlist:
        current = installed.get(tool.get("formula", tool["name"]))
        if not current:
            continue
        release = fetch_release(tool["repo"])
        if not release:
            # Offline or rate-limited: keep the last known result unless already upgraded
            old = previous.get(tool["name"])
            if old and old["from"] == format_version(current):
                updates.append(old)
            continue
        tag, notes = release.get("tag_name", ""), release.get("body") or ""
        level = classify(current, tag, notes)
        if not level:
            continue
        name, to = tool["name"], format_version(tag)
        updates.append({
            "id": "update:%s@%s" % (name, to),
            "kind": "update",
            "name": name,
            "from": format_version(current),
            "to": to,
            "level": level,
            "title": "%s %s → %s [%s]" % (name, format_version(current), to, level),
            "summary": summarize(tool.get("why", ""), notes),
            "url": release.get("html_url", ""),
            "install": upgrade_command(tool),
        })
    write_atomic(cache_path("updates.json"), json.dumps(updates, indent=2))
    write_banner()
    write_atomic(cache_path("last_refresh"), str(int(time.time())))


def discoveries():
    items = []
    for entry in read_json(data_file("RADAR_DISCOVER", "discover.json"), []):
        if shutil.which(entry.get("bin", entry["name"])):
            continue
        items.append({
            "id": "discover:%s" % entry["name"],
            "kind": "discover",
            "name": entry["name"],
            "title": entry["name"],
            "summary": entry.get("why", ""),
            "url": entry.get("url", ""),
            "install": entry["install"],
        })
    return items


def dismissed():
    return set(read_json(cache_path("dismissed.json"), []))


def pending_updates(hidden=None):
    if hidden is None:
        hidden = dismissed()
    return [u for u in read_json(cache_path("updates.json"), []) if u["id"] not in hidden]


def pending():
    """All items awaiting review: workflow updates first, then discoveries."""
    hidden = dismissed()
    return pending_updates(hidden) + [d for d in discoveries() if d["id"] not in hidden]


def find(item_id):
    for item in read_json(cache_path("updates.json"), []) + discoveries():
        if item["id"] == item_id:
            return item
    return None


def write_banner():
    updates = pending_updates()
    if not updates:
        text = ""
    else:
        noun = "update" if len(updates) == 1 else "updates"
        listed = ", ".join(u["title"] for u in updates[:BANNER_MAX_NAMED])
        if len(updates) > BANNER_MAX_NAMED:
            listed += " +%d more" % (len(updates) - BANNER_MAX_NAMED)
        text = "📡 radar: %d workflow %s: %s. Run 'radar' to review.\n" % (len(updates), noun, listed)
    write_atomic(cache_path("banner.txt"), text)


def is_stale():
    try:
        return time.time() - os.path.getmtime(cache_path("last_refresh")) > STALE_AFTER_SECONDS
    except OSError:
        return True


# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

def cmd_list():
    for item in pending():
        print("\t".join([item["id"], item["kind"], item["title"], item["summary"]]))
    return 0


def cmd_show(item_id):
    item = find(item_id)
    if not item:
        print("radar: no such item %r" % item_id, file=sys.stderr)
        return 1
    print(item["title"])
    print("")
    print("Why this matters: %s" % (item["summary"] or "-"))
    if item.get("url"):
        print("More:    %s" % item["url"])
    print("Install: %s" % item["install"])
    return 0


def cmd_dismiss(item_id):
    hidden = dismissed()
    hidden.add(item_id)
    write_atomic(cache_path("dismissed.json"), json.dumps(sorted(hidden), indent=2))
    write_banner()
    return 0


def cmd_install(item_id):
    item = find(item_id)
    if not item:
        print("radar: no such item %r" % item_id, file=sys.stderr)
        return 1
    print("==> %s" % item["install"])
    code = subprocess.call(shlex.split(item["install"]))
    if code == 0 and item["kind"] == "update":
        remaining = [u for u in read_json(cache_path("updates.json"), []) if u["id"] != item_id]
        write_atomic(cache_path("updates.json"), json.dumps(remaining, indent=2))
        write_banner()
    return code


def _self_cmd():
    return "%s %s" % (shlex.quote(sys.executable), shlex.quote(os.path.realpath(__file__)))


def _tui_fzf(items):
    """One fzf round: returns (key, item_id) or (None, None) on quit."""
    lines = "\n".join("\t".join([i["id"], "⬆" if i["kind"] == "update" else "✨",
                                 i["title"], i["summary"]]) for i in items)
    proc = subprocess.run(
        ["fzf", "--delimiter=\t", "--with-nth=2,3", "--no-sort", "--expect=i,s",
         "--prompt=radar> ", "--header=i: install/upgrade · s: dismiss · esc: quit",
         "--preview=%s show {1}" % _self_cmd(), "--preview-window=down,40%,wrap"],
        input=lines, stdout=subprocess.PIPE, text=True)
    out = proc.stdout.splitlines()
    if proc.returncode != 0 or len(out) < 2:
        return None, None
    return out[0], out[1].split("\t")[0]


def _tui_menu(items):
    """Plain fallback when fzf is unavailable: returns (key, item_id) or (None, None)."""
    print("")
    for n, item in enumerate(items, 1):
        tag = "update  " if item["kind"] == "update" else "discover"
        print("  [%d] %s %s" % (n, tag, item["title"]))
        if item["summary"]:
            print("               %s" % item["summary"])
    try:
        answer = input("\nAction (e.g. '1i' install, '1s' dismiss, 'q' quit): ").strip().lower()
    except EOFError:
        return None, None
    m = re.match(r"^(\d+)\s*([is])$", answer)
    if not m or not 1 <= int(m.group(1)) <= len(items):
        return None, None
    return m.group(2), items[int(m.group(1)) - 1]["id"]


def cmd_tui():
    if not (sys.stdin.isatty() and sys.stdout.isatty()):
        return cmd_list()  # never block non-interactive callers (agents, pipes)
    pick = _tui_fzf if shutil.which("fzf") else _tui_menu
    while True:
        items = pending()
        if not items:
            print("📡 radar: nothing to review.")
            return 0
        key, item_id = pick(items)
        if key == "i":
            cmd_install(item_id)
        elif key == "s":
            cmd_dismiss(item_id)
        else:
            return 0


def main(argv):
    cmd, args = (argv[0], argv[1:]) if argv else ("tui", [])
    if cmd == "refresh":
        if "--if-stale" in args and not is_stale():
            return 0
        lock = cache_path("refresh.lock")
        os.makedirs(cache_dir(), exist_ok=True)
        try:
            if time.time() - os.path.getmtime(lock) > 600:
                os.remove(lock)  # stale lock from a crashed/killed refresh
        except OSError:
            pass
        try:
            os.close(os.open(lock, os.O_CREAT | os.O_EXCL))
        except FileExistsError:
            return 0  # another shell is already refreshing
        try:
            refresh()
        finally:
            os.remove(lock)
        return 0
    if cmd == "list":
        return cmd_list()
    if cmd == "tui":
        return cmd_tui()
    if cmd in ("show", "install", "dismiss") and len(args) == 1:
        return {"show": cmd_show, "install": cmd_install, "dismiss": cmd_dismiss}[cmd](args[0])
    if cmd in ("-h", "--help", "help"):
        print(__doc__)
        return 0
    print("radar: unknown command %r (see radar --help)" % " ".join(argv), file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
