# SETUP TERMINAL

Install Base Softwares

```bash
sudo apt install kitty zsh unzip 
```

Download Fonts
```bash
curl -LO "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaCode.zip"
unzip CascadiaCode.zip -d .fonts
rm CascadiaCode.zip
```

Setting Up Oh My ZSH

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Setting Up Starship

```bash
curl -sS https://starship.rs/install.sh | sh
```


Install ZSH Plugins

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/mrjohannchang/zsh-interactive-cd.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-interactive-cd
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

# Config Files

<details>

<summary>ZSH Config</summary>

```bash
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git web-search zsh-autosuggestions zsh-syntax-highlighting zsh-interactive-cd)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

source $HOME/.asdf/asdf.sh

# WINDOWS ALIAS
alias cls="clear"
alias del="rm"
alias copy="cp"
alias del="rm"
alias ren="mv"
alias move='mv'

# NAV ALIAS
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
alias analyze="ytop"
alias top="procs"
alias hell="tokei"
alias find="fdfind"
alias dir="exa --icons"
alias ls="exa --icons -la"
alias l="exa --icons"
alias cd="z"

# PYTHON ALIAS
alias create-venv="python -m venv venv"
alias start-venv="source venv/bin/activate"
alias remove-venv="rm venv -rf"

# KITTY ALIAS
alias icat="kitty +kitten icat"

# APPLICATION ALIAS
alias nano="nano"
alias run="xdg-open"
alias terminal="gnome-terminal"
alias disk="ncdu"
alias vim="nvim"
alias emacs="emacs -nw"
alias npm="pnpm"
alias update-pnpm="curl -fsSL https://get.pnpm.io/install.sh | sh -"

# COMMAND ALIAS
alias reload="source ~/.zshrc"
alias config="nvim ~/.zshrc"
alias whatsapp="google-chrome https://web.whatsapp.com/ &"
alias shutdown="shutdown --n now"
alias clip="xclip -sel clip"
alias git-push="git add . && git commit -m update && git push"

# FUNCTIONS
c () { z "$@" && l; }
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Python
alias py="python"
```

</details>

<details>
<summary>Kitty Config</summary>

```config
font_family Caskaydia Cove Nerd Font 
font_size 14.0
window_padding_width 8 
background_opacity 0.8
```

</details>
