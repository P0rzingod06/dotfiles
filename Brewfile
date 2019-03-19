# Install HomeBrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

tap 'caskroom/cask'

# Install zsh and related
brew 'zsh'
brew 'zsh-completions'

# Install command line utils
brew 'coreutils'
brew 'git'
brew 'libdvdcss'
brew 'trash'
brew 'vim', args: ['with-override-system-vi']

# Install apps
cask 'android-file-transfer'
cask 'firefox'
cask 'handbrake'
cask 'iterm2'
cask 'macdown'
cask 'spectacle'
cask 'vlc'

brew cask install vscode

# Manual Installs   #
#####################

# NVM
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash\n

# SDKMan
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# CatchMouse
git clone https://github.com/round/CatchMouse.git
cp -rf CatchMouse/CatchMouse.app /Applications

# GIT #
########
#
git config --global core.excludesfile ~/.gitignore_global
git config --get core.excludesfile

# Sys Link Files #
##################

ln -sv ~/Projects/.vimrc ~
ln -sv ~/Projects/.zshrc  ~
ln -sv ~/Projects/.bashrc  ~
ln -sv ~/Projects/.gitignore_global  ~

