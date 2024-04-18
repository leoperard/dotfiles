debug:
	echo $${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

zsh:
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	rm ~/.zshrc
	ln -sf zsh/.zshrc ~/.zshrc

p10k: zsh
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $${ZSH_CUSTOM:-$$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	ln -sf zsh/.p10k.zsh ~/.p10k.zsh

tmux:
	git clone https://github.com/gpakosz/.tmux.git ~/.tmux
	ln -sf ~/.tmux/.tmux.conf ~/.tmux.conf
	ln -sf zsh/.tmux.conf.local ~/.tmux.conf.local

all: zsh p10k tmux
