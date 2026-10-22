# setup

My configs and a one-command installer for a fresh **Ubuntu 26.04** machine.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/masterkey-07/setup/main/install.sh)
```

It clones this repo to `~/Repositories/setup`, asks for sudo once, installs everything and
symlinks the configs. It is safe to re-run: steps that are already done are skipped.

## What gets installed

| Step     | What                                                                                                                            |
| -------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `repos`  | apt sources: Google Chrome, VS Code, Claude Desktop, AnyDesk; multiverse + i386                                                 |
| `apt`    | [packages/core.txt](packages/core.txt) + the optional groups below                                                              |
| `shell`  | oh-my-zsh, zsh-autosuggestions / syntax-highlighting / interactive-cd, starship, Caskaydia Cove Nerd Font, zsh as default shell |
| `tools`  | bottom (`btm`), procs, tokei, uv, nvm + Node LTS, Claude Code                                                                   |
| `apps`   | Obsidian, Discord, Steam (.debs from upstream), Focus Timer / GNOME Pomodoro (Flathub)                                      |
| `vscode` | extensions from [dotfiles/vscode/extensions.txt](dotfiles/vscode/extensions.txt)                                                |
| `link`   | symlinks the configs below                                                                                                      |
| `post`   | `gh auth login`, clones my Knowledge vault to `~/Knowledge`                                                                     |

Optional groups (all on by default, each one can be skipped with `--skip`):

- `gaming`: Steam, Lutris, Wine, Chiaki
- `comm`: Discord, Claude Desktop, AnyDesk
- `office`: LibreOffice, Okular, Zathura, MuPDF, texlive-full (several GB)
- `media`: mpv, ffmpeg, flameshot, cava, psensor, lm-sensors, cpupower-gui, speedtest-cli

## Options

```bash
./install.sh --link-only            # only (re)link the configs
./install.sh --only tools           # run a single step (repeatable)
./install.sh --skip office          # skip a step or a group (repeatable)
./install.sh --list                 # list steps and groups
```

## Configs

| Repo                                                           | Linked to                                    |
| -------------------------------------------------------------- | -------------------------------------------- |
| [dotfiles/zsh/.zshrc](dotfiles/zsh/.zshrc)                     | `~/.zshrc`                                   |
| [dotfiles/kitty/kitty.conf](dotfiles/kitty/kitty.conf)         | `~/.config/kitty/kitty.conf`                 |
| [dotfiles/i3/](dotfiles/i3/)                                   | `~/.config/i3`                               |
| [dotfiles/git/.gitconfig](dotfiles/git/.gitconfig)             | `~/.gitconfig`                               |
| [dotfiles/nvim/](dotfiles/nvim/)                               | `~/.config/nvim`                             |
| [dotfiles/vscode/settings.json](dotfiles/vscode/settings.json) | `~/.config/Code/User/settings.json`          |
| [dotfiles/bin/](dotfiles/bin/)                                 | `~/.local/bin/` (`kitty-fast`, `screenshot`) |

Neovim is the editor: `vim`/`vi`/`v` are aliased to `nvim` and it's `$EDITOR`. Its config is
plain options and keymaps, with no plugins.

They are symlinks, so editing them on the machine edits the repo. Commit and push to keep them.
Any file that was already in place is moved to `<file>.bak.<timestamp>` before linking.

To add software, add the package to a list in [packages/](packages/). Use a step script
in [scripts/](scripts/) if it isn't in apt.

## Manual steps

- NVIDIA GPU: `sudo ubuntu-drivers autoinstall`
- Log out and pick the **i3** session on the login screen.
- Before relying on the installer, test it on a fresh 26.04 VM.
