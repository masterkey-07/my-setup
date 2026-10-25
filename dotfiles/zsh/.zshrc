export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""  # starship draws the prompt
plugins=(git web-search zsh-autosuggestions zsh-syntax-highlighting zsh-interactive-cd)

source $ZSH/oh-my-zsh.sh

export EDITOR='nvim'
export VISUAL='nvim'

eval "$(starship init zsh)"

# WINDOWS ALIAS
alias cls="clear"
alias del="rm"
alias copy="cp"
alias ren="mv"
alias move='mv'

# NAVIGATION ALIAS
alias ff="run \"\$(readlink -f \"\$(fdfind --type f | fzf --preview 'bat --style numbers,changes --color=always {}')\")\""
alias gf="cd \"\$(dirname \"\$(readlink -f \"\$(fdfind --type f | fzf)\")\")\""
alias gd="cd \"\$(readlink -f \"\$(fdfind --type d | fzf)\")\""

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
alias dir="eza --icons"
alias l="eza --icons"

# Claude Code sources this file for its own shell; keep its commands on the real tools
if [[ -z $CLAUDECODE ]]; then
  alias find="fdfind"
  alias ls="eza --icons -la"
  alias cd="z"
fi

# KITTY ALIAS
alias icat="kitty +kitten icat"

# APPLICATION ALIAS
alias run="xdg-open"
alias terminal="kitty"
alias disk="ncdu"
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

# COMMAND ALIAS
alias reload="source ~/.zshrc"
alias config="nvim ~/.zshrc"
alias whatsapp="google-chrome https://web.whatsapp.com/ &"
alias shutdown="shutdown now"
alias clip="wl-copy"
# Tracked files only, so stray new files never get committed by accident
alias git-push="git commit -am update && git push"

# OUTPUTS
alias edpoff="swaymsg output eDP-1 disable"
alias edpon="swaymsg output eDP-1 enable"

# FUNCTIONS
c () { z "$@" && l; }
# Without args, `z` would jump to $HOME, so only jump when a target is given
claudeit () { { (( $# == 0 )) || z "$@"; } && claude; }
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Python

alias py="python3"

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

# Language toolchains (rustup, go install, ghcup, dart pub global)
for _dir in "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/.ghcup/bin" "$HOME/.pub-cache/bin"; do
  [ -d "$_dir" ] && export PATH="$_dir:$PATH"
done
unset _dir
[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env"

# Third-party init scripts call find/cd/ls internally, so they must not see
# the aliases above (e.g. find -> fdfind breaks `find -type f`)
_source_without_aliases() {
  setopt local_options no_aliases
  source "$1"
}

# SDKMAN! (Java, Maven, Gradle, Kotlin)
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && _source_without_aliases "$SDKMAN_DIR/bin/sdkman-init.sh"

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
  _source_without_aliases "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() { _load_nvm; nvm "$@"; }

# zoxide must be initialized last
eval "$(zoxide init zsh)"
