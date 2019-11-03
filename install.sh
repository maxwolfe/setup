# Script Directory 
DIR="$(dirname $0)"
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

  apt-get install -y "$PACKAGE"
	ret="$?"

	if [ "$ret" -ne 0 ]; then
		log "$PACKAGE: Failed to Install"
	else
		log "$PACKAGE: Successfully Installed"
	fi
}


clone_and_log () {
	local SOURCE="$1"; shift
	local DEST="$1"; shift

  git clone "$SOURCE" "$DEST"
	ret="$?"

	if [ "$ret" -ne 0 ]; then
		log "$SOURCE: Failed to Clone"
	else
		log "$SOURCE: Successfully Cloned"
	fi

}


python_install_and_log () {
	local VERSION="$1"; shift
	local PACKAGE="$1"; shift

  pip${VERSION} install "$PACKAGE"
	ret="$?"

	if [ "$ret" -ne 0 ]; then
		log "$PACKAGE: Failed to Install"
	else
		log "$PACKAGE: Successfully Installed"
	fi
}


ruby_install_and_log () {
	local PACKAGE="$1"; shift

  gem install "$PACKAGE"
	ret="$?"

	if [ "$ret" -ne 0 ]; then
		log "$PACKAGE: Failed to Install"
	else
		log "$PACKAGE: Successfully Installed"
	fi
}


cp_and_log () {
	local SOURCE="$1"; shift
	local DEST="$1"; shift

  cp "$SOURCE" "$DEST"
	ret="$?"

	if [ "$ret" -ne 0 ]; then
		log "$SOURCE: Failed to Copy"
	else
		log "$SOURCE: Successfully Copied"
	fi

}


install_packages () {
	# Add Repositories

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
	clone_and_log https://github.com/longld/peda.git "$HOME/peda"
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

	## PDF Reader
	install_and_log evince

	## Ruby Install
	clone_and_log https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
	echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$HOME/.bashrc"
	echo 'eval "$(rbenv init -)"' >> "$HOME/.bashrc"
	clone_and_log https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build"
	echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> "$HOME/.bashrc"
	source "$HOME/.bashrc"
	rbenv install 2.4.4
	rbenv global 2.4.4
}

vim_setup () {
	# Vim Setup

	## Vundle: Vim Plugin Manager
	clone_and_log https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"

	## Copy Plugins List
	cp_and_log "$FILES/plugins.vim" "$HOME/.vim/plugins.vim"

	## Setup Colors
	mkdir "$HOME/.vim/colors"
	cp_and_log "$FILES/max.vim" "$HOME/.vim/colors/max.vim"
	cp_and_log "$FILES/vimrc" "$HOME/.vimrc"
	vim +PluginInstall +qall
}


other_packages () {
	# Python Packages

	## Virtualenv
	python_install_and_log "" virtualenv
	python_install_and_log 3 virtualenv

	## Powerline
	python_install_and_log 3 git+git://github.com/Lokaltog/powerline

	# Ruby Packages

	## For Tmuxinator
	ruby_install_and_log tmuxinator

	## For Vagrant
	ruby_install_and_log nokogiri
	ruby_install_and_log ffi
	ruby_install_and_log unf_ext
}


shell_setup() {
	# Shell Setup
	username="$(echo $HOME | sed -e 's/\/home\///g')"
	log "USERNAME=$username"

	## TaskMax Install
	clone_and_log https://github.com/maxwolfe/task-max.git "$HOME/.taskmax"

	## zsh Setup
	usermod -s "$(which zsh)" "$username"
	clone_and_log https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.zsh-syntax-highlighting"
	git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"

	### Copy each config
	PREZ="$HOME/.zprezto/runcoms"
	cp_and_log "$PREZ/zlogin" "$HOME/.zlogin"
	cp_and_log "$PREZ/zlogout" "$HOME/.zlogout"
	cp_and_log "$PREZ/zprofile" "$HOME/.zprofile"
	cp_and_log "$PREZ/zshenv" "$HOME/.zshenv"
	cp_and_log "$FILES/zpreztorc" "$HOME/.zpreztorc"
	cp_and_log "$FILES/zshrc"  "$HOME/.zshrc"

	## Tmux Setup
	clone_and_log https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
	cp "$FILES/tmux.conf" "$HOME/.tmux.conf"
	"$HOME/.tmux/plugins/tpm/scripts/install_plugins.sh"

	## Tmuxinator Setup
	mkdir "$HOME/.bin"
	cp_and_log "$FILES/tmuxinator.zsh" "$HOME/.bin/tmuxinator.zsh"
	tmuxinator doctor

	#Config Main Terminal
	mkdir "$HOME/.config"
	mkdir "$HOME/.config/tmuxinator"
	cp_and_log "$FILES/main.yml" "$HOME/.config/tmuxinator/main.yml"

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
