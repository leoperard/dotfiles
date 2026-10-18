"""Tests for radar. Run with: python3 -m unittest discover -s radar"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
RADAR = os.path.join(HERE, "radar.py")
sys.path.insert(0, HERE)
import radar  # noqa: E402


class ClassifyTest(unittest.TestCase):
    def test_major_bump_is_breaking(self):
        self.assertEqual(radar.classify("1.4.2", "2.0.0", ""), "breaking")

    def test_minor_bump_is_feature(self):
        self.assertEqual(radar.classify("v0.10.4", "v0.11.0", "## Features\n- foo"), "feature")

    def test_bugfix_patch_is_ignored(self):
        self.assertIsNone(radar.classify("3.5", "3.5a", "## Bug fixes\n- fix crash"))

    def test_patch_declaring_breaking_change_is_breaking(self):
        notes = "### ⚠ BREAKING CHANGES\n- `--foo` flag removed"
        self.assertEqual(radar.classify("1.2.3", "1.2.4", notes), "breaking")


class RadarCliCase(unittest.TestCase):
    """Drives the radar CLI as a subprocess against fixture data in a temp dir."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = self.tmp.name
        self.cache = os.path.join(root, "cache")
        self.fixtures = os.path.join(root, "fixtures")
        os.makedirs(os.path.join(self.fixtures, "releases"))
        self.watchlist = os.path.join(root, "watchlist.json")
        self.discover = os.path.join(root, "discover.json")
        self.write_json(self.watchlist, [])
        self.write_json(self.discover, [])
        self.write_json(os.path.join(self.fixtures, "installed.json"), {})

    def tearDown(self):
        self.tmp.cleanup()

    def write_json(self, path, data):
        with open(path, "w") as f:
            json.dump(data, f)

    def read_json(self, path):
        with open(path) as f:
            return json.load(f)

    def track(self, name, repo, installed, tag, body=""):
        tools = [t for t in self.read_json(self.watchlist) if t["name"] != name]
        tools.append({"name": name, "repo": repo, "formula": name,
                      "why": "%s is part of the daily workflow." % name})
        self.write_json(self.watchlist, tools)
        installed_path = os.path.join(self.fixtures, "installed.json")
        versions = self.read_json(installed_path)
        versions[name] = installed
        self.write_json(installed_path, versions)
        release = {"tag_name": tag, "body": body,
                   "html_url": "https://github.com/%s/releases/tag/%s" % (repo, tag)}
        self.write_json(os.path.join(self.fixtures, "releases",
                                     repo.replace("/", "__") + ".json"), release)

    def catalog(self, *entries):
        self.write_json(self.discover, list(entries))

    def run_radar(self, *args):
        env = dict(os.environ, RADAR_CACHE_DIR=self.cache,
                   RADAR_FIXTURE_DIR=self.fixtures,
                   RADAR_WATCHLIST=self.watchlist, RADAR_DISCOVER=self.discover)
        return subprocess.run([sys.executable, RADAR, *args], env=env,
                              capture_output=True, text=True, check=True).stdout

    def banner(self):
        path = os.path.join(self.cache, "banner.txt")
        if not os.path.exists(path):
            return ""
        with open(path) as f:
            return f.read()

    def listed(self):
        return [line.split("\t") for line in self.run_radar("list").splitlines()]


class RefreshTest(RadarCliCase):
    def test_banner_lists_only_workflow_impacting_updates(self):
        self.track("fd", "sharkdp/fd", "9.0.0", "v10.0.0", "## Features\n- new flag")
        self.track("jq", "jqlang/jq", "1.7.0", "jq-1.7.1", "## Bug fixes\n- fix crash")
        self.run_radar("refresh")
        self.assertEqual(
            self.banner().strip(),
            "📡 radar: 1 workflow update: fd 9.0.0 → 10.0.0 [breaking]. Run 'radar' to review.")

    def test_banner_stays_compact_with_many_updates(self):
        for name in ("aa", "bb", "cc", "dd", "ee"):
            self.track(name, "org/" + name, "1.0.0", "1.1.0", "- thing")
        self.run_radar("refresh")
        self.assertEqual(
            self.banner().strip(),
            "📡 radar: 5 workflow updates: aa 1.0.0 → 1.1.0 [feature], bb 1.0.0 → 1.1.0 [feature], "
            "cc 1.0.0 → 1.1.0 [feature] +2 more. Run 'radar' to review.")

    def test_silent_when_nothing_workflow_impacting(self):
        self.track("jq", "jqlang/jq", "1.7.0", "jq-1.7.1", "## Bug fixes\n- fix crash")
        self.track("tmux", "tmux/tmux", "3.5", "3.5", "")
        self.run_radar("refresh")
        self.assertEqual(self.banner(), "")
        self.assertEqual(self.run_radar("list"), "")

    def test_list_explains_why_an_update_matters(self):
        notes = ("## What's new\n\n"
                 "### Features\n"
                 "- Add `--format` option for custom output (#1234)\n"
                 "* [Hyperlink support](https://example.com/pr/1)\n"
                 "- Something third\n")
        self.track("fd", "sharkdp/fd", "9.0.0", "v9.1.0", notes)
        self.run_radar("refresh")
        self.assertEqual(self.listed(), [[
            "update:fd@9.1.0", "update", "fd 9.0.0 → 9.1.0 [feature]",
            "fd is part of the daily workflow. New: Add `--format` option for custom output; "
            "Hyperlink support.",
        ]])

    def test_list_offers_curated_tools_not_yet_installed(self):
        self.catalog(
            {"name": "zoxide", "bin": "radar-test-not-a-real-binary",
             "install": "brew install zoxide", "why": "Jump to frecent dirs; replaces autojump."},
            {"name": "already-there", "bin": "sh",
             "install": "true", "why": "Already on PATH, so never suggested."})
        self.run_radar("refresh")
        self.assertEqual(self.listed(), [[
            "discover:zoxide", "discover", "zoxide", "Jump to frecent dirs; replaces autojump.",
        ]])
        self.assertEqual(self.banner(), "", "discovery alone must not trigger the banner")


class DismissTest(RadarCliCase):
    def test_dismissed_update_leaves_banner_and_list(self):
        self.track("fd", "sharkdp/fd", "9.0.0", "v9.1.0", "- thing")
        self.track("uv", "astral-sh/uv", "0.4.0", "0.5.0", "- other")
        self.run_radar("refresh")
        self.run_radar("dismiss", "update:fd@9.1.0")
        self.assertEqual(
            self.banner().strip(),
            "📡 radar: 1 workflow update: uv 0.4.0 → 0.5.0 [feature]. Run 'radar' to review.")
        self.assertEqual([row[0] for row in self.listed()], ["update:uv@0.5.0"])

    def test_dismissal_survives_refresh_until_newer_release(self):
        self.track("fd", "sharkdp/fd", "9.0.0", "v9.1.0", "- thing")
        self.run_radar("refresh")
        self.run_radar("dismiss", "update:fd@9.1.0")
        self.run_radar("refresh")
        self.assertEqual(self.banner(), "")
        self.track("fd", "sharkdp/fd", "9.0.0", "v9.2.0", "- newer thing")
        self.run_radar("refresh")
        self.assertEqual([row[0] for row in self.listed()], ["update:fd@9.2.0"])

    def test_dismissed_discovery_is_not_suggested_again(self):
        self.catalog({"name": "zoxide", "bin": "radar-test-not-a-real-binary",
                      "install": "brew install zoxide", "why": "Smarter cd."})
        self.run_radar("dismiss", "discover:zoxide")
        self.assertEqual(self.run_radar("list"), "")


if __name__ == "__main__":
    unittest.main()
