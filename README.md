# my-setup

My configs and a one-command installer for a fresh **Ubuntu 26.04** machine.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/masterkey-07/my-setup/main/install.sh)
```

It clones this repo to `~/Repositories/my-setup`, asks for sudo once, installs everything and
symlinks the configs. It is safe to re-run: steps that are already done are skipped.

## What gets installed

| Step     | What                                                                                                                                                                                        |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `repos`  | apt sources: Google Chrome, Brave, VS Code, Claude Desktop (comm), AnyDesk (comm), Dart (dev); multiverse + i386                                                                            |
| `apt`    | [packages/core.txt](packages/core.txt) + the optional groups below; Chrome policy (KeePassXC-Browser, no built-in password manager)                                                         |
| `shell`  | oh-my-zsh, zsh-autosuggestions / syntax-highlighting / interactive-cd, starship, Caskaydia Cove Nerd Font, zsh as default shell                                                             |
| `tools`  | bottom (`btm`), procs, tokei, Neovim, uv, nvm + Node LTS, Claude Code, rustup, uair (pomodoro); with `dev`: rust-analyzer, gopls, ghcup, SDKMAN! (Java, Maven, Gradle, Kotlin), Clojure CLI |
| `apps`   | Obsidian, Discord, Steam (.debs from upstream)                                                                                                                                              |
| `vscode` | extensions from [dotfiles/vscode/extensions.txt](dotfiles/vscode/extensions.txt)                                                                                                            |
| `sync`   | Syncthing service, `~/Books` and `~/Vault` (versioned) folders                                                                                                                              |
| `link`   | symlinks the configs below (KeePassXC ones are copied once)                                                                                                                                 |
| `post`   | `gh auth login`, clones my Knowledge vault to `~/Knowledge`                                                                                                                                 |

Optional groups (all on by default, each one can be skipped with `--skip`):

- `gaming`: Steam, Lutris, Wine, Chiaki
- `comm`: Discord, Claude Desktop, AnyDesk
- `office`: LibreOffice, Zathura, Readest, texlive-full (several GB)
- `media`: mpv, ffmpeg, cava
- `dev`: Go, Dart, PHP + Composer, PostgreSQL, CMake + Ninja + Clang, build headers (incl. GTK 3), Docker engine + Compose v2 + buildx
  (adds you to the `docker` group), and the toolchains from the `tools` step (rust-analyzer, Haskell, JVM, Clojure)

## Options

```bash
./install.sh --link-only            # only (re)link the configs
./install.sh --only tools           # run a single step (repeatable)
./install.sh --skip office          # skip a step or a group (repeatable)
./install.sh --list                 # list steps and groups
```

## Healthcheck

```bash
./healthcheck.sh                    # check packages, tools, shell, apps, symlinks, config syntax, logins
./healthcheck.sh --skip gaming      # ignore an optional group (repeatable)
```

It only reads, never installs or links, and exits 1 if anything fails. Re-run `./install.sh`
(or `--only <step>`) to fix what it reports.

## Configs

| Repo                                                           | Linked to                                    |
| -------------------------------------------------------------- | -------------------------------------------- |
| [dotfiles/zsh/.zshrc](dotfiles/zsh/.zshrc)                     | `~/.zshrc`                                   |
| [dotfiles/kitty/kitty.conf](dotfiles/kitty/kitty.conf)         | `~/.config/kitty/kitty.conf`                 |
| [dotfiles/sway/](dotfiles/sway/)                               | `~/.config/sway`                             |
| [dotfiles/git/.gitconfig](dotfiles/git/.gitconfig)             | `~/.gitconfig`                               |
| [dotfiles/nvim/](dotfiles/nvim/)                               | `~/.config/nvim`                             |
| [dotfiles/vscode/settings.json](dotfiles/vscode/settings.json) | `~/.config/Code/User/settings.json`          |
| [dotfiles/bin/](dotfiles/bin/)                                 | `~/.local/bin/` (`kitty-fast`, `screenshot`) |
| [dotfiles/uair/uair.toml](dotfiles/uair/uair.toml)             | `~/.config/uair/uair.toml`                   |
| [dotfiles/systemd/](dotfiles/systemd/)                         | `~/.config/systemd/user/` (timers enabled)   |

Neovim is the editor: `vim`/`vi`/`v` are aliased to `nvim` and it's `$EDITOR`. Its config is
plain options and keymaps, with no plugins.

They are symlinks, so editing them on the machine edits the repo. Commit and push to keep them.
Any file that was already in place is moved to `<file>.bak.<timestamp>` before linking.

KeePassXC rewrites its own config, so [dotfiles/keepassxc/](dotfiles/keepassxc/) is copied once
instead (an existing file is never overwritten): `keepassxc.ini` to `~/.config/keepassxc/`, and
the Chrome native-messaging manifest to `~/.config/google-chrome/NativeMessagingHosts/`.

## Password safe

KeePassXC, with the vault in `~/Vault`, synced by Syncthing (folder `my-vault`, with staggered
versioning so a bad or deleted vault can be recovered). It starts minimized with Sway (`$mod+x`
brings it up) and also acts as the Secret Service keyring and the SSH agent. Chrome's own
password manager is turned off by policy and the KeePassXC-Browser extension is force-installed
([dotfiles/chrome/policies/](dotfiles/chrome/policies/)). Vault and key files are gitignored.

## Books

`~/Books` is synced by Syncthing and read in Readest and Zathura. `book-check` scans it for
content that could run code or phone home when a book is opened, and a weekly user timer
(`book-check.timer`) runs it with a desktop notification when something is flagged.

```bash
book-check                          # scan ~/Books; exits 1 if anything is DANGER
book-check some.pdf other.epub      # specific books or folders
book-check --mark-reviewed some.pdf # mute a flagged book until the file changes
```

- **DANGER**: PDF JavaScript that runs by itself (on open, page or field events), `/Launch` of a
  program, embedded executables; EPUB scripts it ships or loads remotely, `javascript:` URLs,
  XML entities, path traversal, zip bombs; files that aren't what their extension says.
- **REVIEW**: JavaScript behind links, `/Launch` of a file next to the book, embedded files,
  forms that submit data, EPUB event handlers, remote images/styles, malformed files.

ClamAV (`office` group) adds a second opinion with default signatures only. Its PUA heuristics
are left off because they flag ordinary PDFs, and it misses a lot of malware, so a ClamAV hit
is only a REVIEW and the structural checks decide.

To add software, add the package to a list in [packages/](packages/). Use a step script
in [scripts/](scripts/) if it isn't in apt.

## Manual steps

- NVIDIA GPU: the driver is installed automatically; reboot once afterwards.
- Log out and pick the **Sway (hybrid GPU)** session on the login screen.
- Password safe, first machine only: create `~/Vault/main.kdbx` in KeePassXC (Argon2id, a
  generated 6–7 word passphrase, written down once and kept offline). Import Chrome's passwords
  (export a CSV from Google Password Manager, import it, then `shred -u` the CSV), delete them
  from the Google account, and share the `Vault` folder with the phone in Syncthing.
- Password safe, every machine: with the vault unlocked, run `gh auth logout && gh auth login`
  so the GitHub token moves into the vault instead of `~/.config/gh/hosts.yml`.
- Keep 2FA codes for Google and GitHub in a separate authenticator app, and copy the vault
  to an offline USB drive now and then.
- Before relying on the installer, test it on a fresh 26.04 VM.
