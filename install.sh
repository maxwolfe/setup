# Script Directory 
DIR="$(dirname ${BASH_SOURCE[0]})"
# Files Directory
FILES="$DIR/files"
# Log File
LOG_FILE="/var/log/max_setup.log"


log () {
	local MESSAGE="$1"; shift

	# If log file doesn't exist, create it
	if [ ! -f "$LOG_FILE" ]; then
		touch "$LOG_FILE"
	fi

	echo "$(date +%T): $MESSAGE" >> "$LOG_FILE"
}


install_and_log () {
	local PACKAGE="$1"; shift

	install_and_log "$PACKAGE"
	ret="$?"

	if [ "$ret" -ne 0 ]; then
		log "$PACKAGE: Failed to Install"
	fi

	log "$PACKAGE: Successfully Installed"
}


install_packages () {
	# Add Repositories

	## Ruby
	apt-add-repository -y ppa:brightbox/ruby-ng
	## Tmux
	add-apt-repository -y ppa:pi-rho/dev


	# Update Repositories
	apt-get update

	# Installations

	## Git
	install_and_log git

	## Copy and Pasting
	install_and_log xclip

	## Install Virtualbox
	install_and_log virtualbox

	## Headless Virtual Machines
	install_and_log vagrant

	## Process/Processor Analytics
	install_and_log htop

	## Terminal Multiplexer (TODO: Update Tmux Configs)
	install_and_log tmux=2.0-1~ppa1~t

	## Python Package Installer
	install_and_log python-pip
	install_and_log python3-pip

	## Ability to Install Debian Packages
	install_and_log gdebi

	## Debugging
	install_and_log gdb
	git clone https://github.com/longld/peda.git "$HOME/peda"
	echo "source $HOME/.peda/peda.py" >> "$HOME/.gdbinit"

	## Better SSH
	install_and_log mosh

	## Better GREP
	install_and_log ack-grep

	## File Search
	git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
	yes | "$HOME/.fzf/install"

	## Better Traceroute
	install_and_log mtr

	## Better Disk Usage Util
	install_and_log pydf

	##Better WGet
	install_and_log aria2

	## Zsh
	install_and_log zsh

	## Ruby 2.4
	install_and_log ruby2.4 ruby2.4-dev

	## PDF Reader
	install_and_log evince
}

vim_setup () {
	# Vim Setup

	## Vundle: Vim Plugin Manager
	git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"

	## Copy Plugins List
	cp "$FILES/plugins.vim" "$HOME/.vim/plugins.vim"

	## Setup Colors
	mkdir "$HOME/.vim/colors"
	cp "$FILES/max.vim" "$HOME/.vim/colors/max.vim"
	cp "$FILES/vimrc" "$HOME/.vimrc"
	vim +PluginInstall +qall
}


other_packages () {
	# Python Packages

	## Virtualenv
	pip install virtualenv
	pip3 install virtualenv

	## Powerline
	pip3 install git+git://github.com/Lokaltog/powerline

	# Ruby Packages

	## For Tmuxinator
	gem install tmuxinator

	## For Vagrant
	gem install nokogiri
	gem install ffi
	gem install unf_ext
}


shell_setup() {
	# Shell Setup
	username="$(echo $HOME | sed -e 's/\/home\///g')"

	## TaskMax Install
	git clone https://github.com/maxwolfe/task-max.git "$HOME/.taskmax"

	## zsh Setup
	usermod -s "$(which zsh)" "$username"
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh-syntax-highlighting"
	git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"

	### Copy each config
	PREZ=~/.zprezto/runcoms
	cp "$PREZ/zlogin" "$HOME/.zlogin"
	cp "$PREZ/zlogout" "$HOME/.zlogout"
	cp "$PREZ/zprofile" "$HOME/.zprofile"
	cp "$PREZ/zshenv" "$HOME/.zshenv"
	cp "$FILES/zpreztorc" "$HOME/.zpreztorc"
	cp "$FILES/zshrc"  "$HOME/.zshrc"

	## Tmux Setup
	git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
	cp "$FILES/tmux.conf" "$HOME/.tmux.conf"
	"$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"

	## Tmuxinator Setup
	mkdir "$HOME/.bin"
	cp "$FILES/tmuxinator.zsh" "$HOME/.bin/tmuxinator.zsh"
	tmuxinator doctor

	#Config Main Terminal
	mkdir "$HOME/.config"
	mkdir "$HOME/.config/tmuxinator"
	cp "$FILES/main.yml" "$HOME/.config/tmuxinator/main.yml"

	#Powerline Fonts
	wget https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf
	mv PowerlineSymbols.otf /usr/share/fonts/
	fc-cache -vf
	mv 10-powerline-symbols.conf /etc/fonts/conf.d/
	echo "export TERM=xterm-256color" >> "$HOME/.bashrc"
}


main () {
	# Install OS Packages
	install_packages
	log "Packages Installed"

	# Setup vim
	vim_setup
	log "vim Setup Completed"

	# Install Other Packages
	other_packages
	log "Other Package Install Complete"

	# Setup Shell
	shell_setup
	log "Shell Setup Complete"

	# Reboot Machine
	reboot
}


main
