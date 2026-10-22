
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git web-search zsh-autosuggestions zsh-syntax-highlighting zsh-interactive-cd)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor (git, sudoedit, crontab -e, ...)
export EDITOR='nvim'
export VISUAL='nvim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

eval "$(starship init zsh)"

# WINDOWS ALIAS
alias cls="clear"
alias del="rm"
alias copy="cp"
alias ren="mv"
alias move='mv'

# NAVIGATION ALIAS
alias ff="run \"\$(readlink -f \"\$(find . --type f | fzf --preview 'bat --style numbers,changes --color=always {}')\")\""
alias gf="cd \"\$(dirname \"\$(readlink -f \"\$(find . --type f | fzf)\")\")\""
alias gd="cd \"\$(readlink -f \"\$(find . --type d | fzf)\")\""

# APT ALIAS
alias install="sudo apt install"
alias autoremove="sudo apt autoremove"
alias dist-upgrade="sudo apt dist-upgrade"
alias upgrade="sudo apt upgrade"
alias update="sudo apt update"
alias remove="sudo apt remove"
alias update-system="update && upgrade && dist-upgrade && autoremove"

# RUST CLI ALIAS
alias analyze="btm"
alias top="procs"
alias hell="tokei"
alias find="fdfind"
alias dir="eza --icons"
alias ls="eza --icons -la"
alias l="eza --icons"
alias cd="z"

# KITTY ALIAS
alias icat="kitty +kitten icat"

# APPLICATION ALIAS
alias run="xdg-open"
alias terminal="gnome-terminal"
alias disk="ncdu"
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# COMMAND ALIAS
alias reload="source ~/.zshrc"
alias config="nvim ~/.zshrc"
alias whatsapp="google-chrome https://web.whatsapp.com/ &"
alias shutdown="shutdown --n now"
alias clip="xclip -sel clip"
alias git-push="git add . && git commit -m update && git push"

# XRANDR
alias xauto="xrandr --auto"
alias edpoff="xrandr --output eDP --off" 
alias edpon="xrandr --output eDP --auto" 

# FUNCTIONS
c () { z "$@" && l; }
# Without args, `z` would jump to $HOME, so only jump when a target is given
claudeit () { { (( $# == 0 )) || z "$@"; } && claude; }
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Python

alias py="python"

# UV
if [ -f "$HOME/.local/bin/env" ]; then . "$HOME/.local/bin/env"; else export PATH="$HOME/.local/bin:$PATH"; fi
# Cached uv completion (regenerated only when the uv binary changes)
if (( $+commands[uv] )); then
  _uv_comp="$HOME/.cache/zsh/uv-completion.zsh"
  if [[ ! -s $_uv_comp || $commands[uv] -nt $_uv_comp ]]; then
    mkdir -p "${_uv_comp:h}" && uv generate-shell-completion zsh > "$_uv_comp"
  fi
  source "$_uv_comp"; unset _uv_comp
fi

# Language toolchains (rustup, go install, ghcup)
for _dir in "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/.ghcup/bin"; do
  [ -d "$_dir" ] && export PATH="$_dir:$PATH"
done
unset _dir

# NVM
# Lazy-load nvm: only sourced the first time node/npm/npx/nvm is run
export NVM_DIR="$HOME/.nvm"
# Put the default node on PATH right away so global npm tools work without loading nvm
_nvm_default="$NVM_DIR/versions/node/$(cat "$NVM_DIR/alias/default" 2>/dev/null)"
[ -d "$_nvm_default/bin" ] || _nvm_default=$(print -l "$NVM_DIR"/versions/node/v*(N) | sort -V | tail -1)
[ -d "$_nvm_default/bin" ] && export PATH="$_nvm_default/bin:$PATH"
unset _nvm_default
_load_nvm() {
  unset -f nvm _load_nvm
  \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { _load_nvm; nvm "$@"; }

# zoxide must be initialized last
eval "$(zoxide init zsh)"
