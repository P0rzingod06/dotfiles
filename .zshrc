# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/Users/michael.gassert/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git sublime)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/michael.gassert/.sdkman"
[[ -s "/Users/michael.gassert/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/michael.gassert/.sdkman/bin/sdkman-init.sh"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

### Android
export ANDROID_SDK_ROOT="/Users/michael.gassert/Library/Android/sdk/"
export ANDROID_HOME="/Users/michael.gassert/Library/Android/sdk"
export JAVA_HOME="/Users/michael.gassert/.sdkman/candidates/java/current"
export PATH=/Users/michael.gassert/Library/Android/sdk/platform-tools/:$PATH
export PATH=$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools:$PATH
export PATH=$PATH:~/$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

##Aliases##
###########

##Navigation
alias cda="cd ~/Projects/albums"
alias cdts="cd ~/Projects/target-spray"

##Easy Open
alias Android="open /Applications/Android\ Studio.app/"
alias Xcode="open /Applications/Xcode.app/"
alias Macdown="open /Applications/Macdown.app/"
alias PostMan="open /Applications/Postman.app/"
alias Insomnia="open /Applications/Insomnia.app/"
alias LiceCap="open /Applications/LICEcap.app/"

##Git
alias gai="git add --interactive"
alias grh="git reset --hard"
alias grim="git rebase -i master"
alias grid="git rebase -i dev"
alias gbda="git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D"
alias ggpushf="ggpush --force"
alias gapan="git add --intent-to-add . && git add --patch"
alias gca="git commit --amend"
alias gan="git add -N ."
alias gstall="git stash --all"
alias gcd="git checkout dev"

##UI
alias gs="grunt serve"
alias rios="react-native run-ios"
alias rand="react-native run-android"
alias srand="sudo react-native run-android"
alias rdt="react-devtools"
alias ni="npm install"
alias rnmni="rm -rf node_modules && npm install"

##Grails
alias gra="grails run-app"

##Editor
alias code="code ."

#Fun
alias rnm="rm -rf ./node_modules"
alias weather="curl wttr.in"

###-tns-completion-start-###
if [ -f /Users/michael.gassert/.tnsrc ]; then 
    source /Users/michael.gassert/.tnsrc 
fi
###-tns-completion-end-###
