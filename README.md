# dotfiles

Modern development environment configuration files optimized for productivity and visual consistency. This setup provides a comprehensive development environment with integrated tools for coding, git workflow, terminal enhancement, and system monitoring.

**Key Features:**
- 🎨 **Consistent Theming**: [Catppuccin Mocha theme](https://github.com/catppuccin/catppuccin) across all applications
- 🚀 **Parallel Installation**: 40-60% faster setup with concurrent package installation
- ⚡ **Performance Optimized**: Fast startup times and efficient resource usage
- 🔧 **Development Focused**: Comprehensive language support and development tools
- 📦 **Automated Setup**: One-script installation for GitHub Codespaces
- 🐚 **Modern Shell**: Fish shell with starship prompt and productivity enhancements

All configurations use the [Catppuccin Mocha theme](https://github.com/catppuccin/catppuccin) for a consistent and visually appealing look across all tools and applications.

## Installation

### Automated Installation (Recommended)

For GitHub Codespaces, the setup is fully automated with **parallel installation** and **fast track** for essential tools:
```bash
./install.sh                    # Fast track mode: Essential tools ready in ~30s
./install.sh --sequential       # Original sequential mode (10-15 minutes)
./install.sh --help             # See all options
```

**Fast Track Optimization:** Essential tools (tmux + plugins + tmuxinator + nvim) are set up immediately in ~30 seconds, while other development tools install in the background.

**Fast Track Priority (ready in ~20 seconds)**:
- ✅ tmux configuration and plugins (TPM + all plugins installed)
- ✅ tmuxinator for session management  
- ✅ nvim configuration (plugins sync in background)
- ✅ starship prompt, FZF, LazyGit

**Background Installations (non-blocking)**:
- 🦀 Rust development tools (bat, rg, fd, eza, zoxide, atuin)
- 📦 NPM language servers and development tools
- 🔌 Neovim plugins and Mason language servers  
- 🛠️ Additional development tools (delta, yq, protobuf, luarocks)

**New Background Installation:** The parallel mode now runs Rust/Cargo tools, NPM packages, and Neovim plugins in the background, allowing you to start using your environment immediately while development tools install in the background.

**Visual Progress Indicator:** When using tmux, a spinning indicator (   ) appears in the status line showing active background installations with the same animation used by lualine in nvim.

**Background Installation Monitoring:**
```bash
# Check installation status
./scripts/check-rust-install.sh      # Rust tools (bat, rg, fd, etc.)
./scripts/check-npm-install.sh       # NPM packages (language servers, etc.)
./scripts/check-neovim-setup.sh      # Neovim plugins and Mason tools

# Monitor installation progress
tail -f ~/.dotfiles_rust_install.log    # Rust tools progress
tail -f ~/.dotfiles_npm_install.log     # NPM packages progress
tail -f ~/.dotfiles_neovim_setup.log    # Neovim setup progress

# Wait for completion (if needed)
wait $(cat ~/.dotfiles_rust_install.pid)  # Wait for Rust tools
wait $(cat ~/.dotfiles_npm_install.pid)   # Wait for NPM packages
wait $(cat ~/.dotfiles_neovim_setup.pid)  # Wait for Neovim setup
```

**Performance:** The new parallel installation reduces foreground setup time by **93%** - from 5+ minutes down to ~20 seconds for immediate productivity!

### Raspberry Pi Installation

A Raspberry Pi (64-bit Raspberry Pi OS, `arm64`) gets the whole setup — apt
packages, mise and every CLI tool, config symlinks, tmux/neovim/herdr plugins —
from one command:

```bash
git clone https://github.com/djensenius/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install-pi
```

It detects whether it needs `sudo`, escalates only for apt, `/etc/shells` and
`chsh`, backs up any config it replaces, and is safe to re-run after a
`git pull`.
Add `--fish-shell` to make fish your login shell, or `--dry-run` to preview.

See [pi/README.md](pi/README.md) for the full step list and options.

### macOS Installation

A Mac uses the Homebrew-aware bootstrapper:

```bash
git clone https://github.com/djensenius/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install-mac
```

The thin `install-mac` entry point runs `mac/install.sh`. It checks the machine,
uses `mac/Brewfile` for curated Homebrew taps/formulae/fonts/terminal casks,
links the repo-owned dotfiles from `mac/links.txt`, trusts and installs the
`mise` tools, installs only missing Herdr plugins from `herdr/plugins.txt`, syncs
TPM and Neovim plugins, and then runs `./install-agent-stack`. Personal GUI
apps live in `mac/Brewfile.apps` and are installed only when you pass `--apps`.
The Brewfiles are curated from this laptop; `brew bundle dump` is useful for
read-only drift discovery but raw dumps should not be committed.

Useful flags:

```bash
./install-mac --dry-run          # show planned actions, change nothing
./install-mac --check            # read-only drift check; exits 2 on drift
./install-mac --only links,mise  # run a subset of sections
./install-mac --skip agent-stack # skip a section
./install-mac --apps             # include personal GUI casks
./install-mac --drift            # diff current Homebrew state against Brewfiles
./install-mac --adopt-gitconfig  # move ~/.gitconfig to ~/.gitconfig.local first
./install-mac --fish-shell --yes # opt in to chsh for Homebrew fish
```

The macOS bootstrap never installs Homebrew for you, upgrades packages, cleans up
or uninstalls packages or Herdr plugins, applies macOS defaults, creates secrets
or SSH/GPG keys, logs in to services such as `gh`, 1Password or the App Store, or
loads launchd agents. Anything it replaces (links, files, an incomplete TPM
checkout) is moved to `~/.dotfiles-backup/<timestamp>/`. If the legacy Herdr
plugin `herdr-picker-plus` is installed, it reports it (drift under `--check`)
and skips `herdr-navigator` until you run
`herdr plugin uninstall herdr-picker-plus`. `~/.gitconfig` is linked only when missing or already correct; use
`--adopt-gitconfig` to move machine-local settings to `~/.gitconfig.local`,
which the repo config includes last so local values win. Keep signing and
machine-local Git settings there, for example:

```gitconfig
[user]
  signingkey = ~/.ssh/id_rsa.pub
[commit]
  gpgsign = true
[gpg]
  format = ssh
[credential]
  helper = osxkeychain
```

The repo `gitconfig` keeps the shared identity (`user.name` and `user.email`)
so machines that already link `~/.gitconfig` continue to commit after a pull.

### After `git pull` on another device

Repo-managed dotfiles are intended to keep working after a normal `git pull`.
If a machine already has the repo links installed, linked files such as Fish,
Neovim, tmux, Herdr scripts/config, GitHub CLI config, and `~/.gitconfig` update
as soon as the clone updates. Machine-local state stays outside those links:
Herdr and `gh` keep real config directories, secrets and credentials stay in
local files such as `~/.gitconfig.local`, and installers back up drift before
replacing repo-owned paths.

Use the platform installer when a pull changes links, copied config, packages or
plugin manifests:

```bash
# macOS: inspect first, then repair/sync repo-owned links and generated state
./install-mac --check            # read-only; exits 2 when repo-managed state drifted
./install-mac                    # safe to re-run; backs up replaced repo-owned paths

# Raspberry Pi: relink configs and refresh mise/tmux/Neovim/Herdr plugin state
git pull
./install-pi                     # or ./install-pi --dry-run to preview

# Pi/Herdr agent stack: rerun whenever pi/agent-stack changes
./install-agent-stack
```

On macOS, `./install-mac --check` is the safe post-pull drift detector. It
validates expected links and install targets without writing; run the full
installer when it reports drift or when a pulled change updates Homebrew, mise,
TPM, Neovim, Herdr plugins, or the Pi/Herdr agent stack. On Raspberry Pi,
`./install-pi` is the supported post-pull refresh path and remains idempotent;
it links repo configs, copies the Pi-specific mise manifest, and re-runs the
package/plugin sync steps that plain symlinks cannot cover.

`./install-agent-stack` merges shared Pi config into `~/.pi/agent` instead of
replacing the directory. Non-overlapping user state, such as extra local MCP
servers or unrelated Pi settings, is preserved, while repository-owned defaults
such as shared model/theme values, managed package sources, and the shared
`playwright`/`context7` MCP server definitions are intentionally reapplied on
each run. Re-run it after pulling changes under `pi/agent-stack/`; package
refreshes such as Playwright browser downloads may still need the command called
out by Pi or the MCP server. GitHub Codespaces remains a bootstrap environment:
`./install.sh` is the setup entry point, not a continuous post-pull repair
service.

### Manual Local Installation

For local installation, most configurations can be symlinked to your `~/.config` directory:

1. **Clone this repository:**
   ```bash
   git clone https://github.com/djensenius/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Symlink configurations:**
   ```bash
   # Core shell and editor configs
   ln -sf ~/.dotfiles/fish ~/.config/
   ln -sf ~/.dotfiles/nvim ~/.config/
   ln -sf ~/.dotfiles/starship.toml ~/.config/
   
   # Terminal multiplexer
   ln -sf ~/.dotfiles/tmux ~/.config/
   
   # Development tools
   ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
   ln -sf ~/.dotfiles/gitignore_local ~/.gitignore_local
   ```

3. **Special setup for TMUX:**
   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ~/.tmux/plugins/tpm/scripts/install_plugins.sh
   ```

4. **Special setup for Herdr:**
   Herdr keeps sockets, logs and its own managed plugin checkouts inside
   `~/.config/herdr`, so link the individual pieces rather than the directory.
   ```bash
   mkdir -p ~/.config/herdr
   ln -sf ~/.dotfiles/herdr/config.toml ~/.config/herdr/config.toml
   ln -sfn ~/.dotfiles/herdr/scripts ~/.config/herdr/scripts
   ```
   Then install the plugins listed in the [herdr](#herdr) section below.

5. **Install required tools** (see [Applications](#applications) section for details)

See the [install.sh](install.sh) script for the complete automated setup process used in GitHub Codespaces.

## Overview

This dotfiles collection includes configurations for:

- **🖥️ Terminal & Shell**: Fish shell with starship prompt, tmux and herdr multiplexers
- **📝 Editor**: Neovim with 46+ plugins for modern development ([details](nvim/README.md))
- **🔍 Search & Navigation**: fzf, ripgrep, fd, eza, zoxide for enhanced file operations
- **📊 Git Workflow**: lazygit, delta, gitsigns integration for visual git management
- **🔧 Development Tools**: Language servers, formatters, linters, and debugging tools
- **📱 System Monitoring**: bottom, fastfetch, k9s for system and cluster monitoring
- **🎨 Consistent Theming**: Catppuccin Mocha theme across all applications

## Applications

### [atuin](https://atuin.sh) ([repo](https://github.com/ellie/atuin))
Atuin is a powerful and customizable shell history manager.
- **Directory**: `atuin/`

### [bat](https://github.com/sharkdp/bat)
Bat is a cat clone with syntax highlighting and Git integration.
- **Directory**: `bat/`

### [bottom](https://github.com/ClementTsang/bottom)
Bottom is a cross-platform graphical process/system monitor.
- **Directory**: `bottom/`

### cloud-sync
A deletion-aware sync between selected `~/Documents` folders and OneDrive / Google Drive.
Two-way pairs merge newest-wins and propagate deletions after confirmation; one-way pairs
treat the source as authoritative. Deletions are detected against a per-pair state manifest,
so a file modified since the last snapshot is re-copied instead of deleted.
- **Script**: `scripts/onedrive_sync.py`
- **Fish function**: `fish/functions/cloud-sync.fish`
- **Usage**: `cloud-sync`, `cloud-sync --dry-run`, `cloud-sync --only NAME`
- **Exit status**: non-zero if any transfer, delete or listing failed, so it is safe to schedule

Cloud destinations go through [rclone](https://rclone.org), which `install.sh` does
**not** provision. Install it and create the remotes the pairs refer to — `onedrive`
and `gdrive` — before the first run:

```bash
brew install rclone
rclone config   # create a remote named "onedrive", then one named "gdrive"
rclone listremotes   # expect: gdrive:  onedrive:
cloud-sync --dry-run # plans without touching anything or prompting
```

The remote names are the `Dest(...)` first argument in `scripts/onedrive_sync.py`, so
renaming a remote means updating `PAIRS` to match. Without the remotes, a run fails
loudly rather than mistaking the unreachable destination for an empty one.

### [delta](https://github.com/dandavison/delta)
Delta is a syntax-highlighting pager for git, diff, and grep output.
- **Configuration**: Integrated into `gitconfig`

### [eza](https://github.com/eza-community/eza)
Eza is a modern replacement for ls with colors, icons, and git integration.
- **Installation**: Via cargo

### [codespaces](https://github.com/github/codespaces)
Codespaces is a cloud development environment provided by GitHub.
- **Directory**: `.devcontainer/`
- **Files**: `install.sh`, `prettierrc.json`

### [fastfetch](https://github.com/LinusDierheimer/fastfetch)
Fastfetch is a neofetch-like tool for fetching system information.
- **Directory**: `fastfetch/`

### [fzf](https://github.com/junegunn/fzf)
Fzf is a command-line fuzzy finder for files, commands, and more.
- **Installation**: Via git clone to `~/.fzf`

### [fd](https://github.com/sharkdp/fd)
Fd is a simple, fast and user-friendly alternative to find.
- **Installation**: Via cargo (as fd-find)

### [Fish](https://fishshell.com) ([repo](https://github.com/fish-shell/fish-shell))
Fish is a smart and user-friendly command line shell.
- **Directory**: `fish/`

### [gh](https://cli.github.com) ([repo](https://github.com/cli/cli))
Gh is GitHub’s official command line tool.
- **Directory**: `gh/`

### [gh-dash](https://github.com/dlvhdr/gh-dash)
Gh-dash is a GitHub CLI tool to view and manage issues and pull requests in a terminal dashboard.
- **Directory**: `gh-dash/`

### [git](https://git-scm.com) ([repo](https://github.com/git/git))
Git is a distributed version control system.
- **Files**: `gitconfig`, `gitignore-local`

### [gitmux](https://github.com/arl/gitmux)
Gitmux is a Tmux status line for Git.
- **File**: `gitmux.conf`

### [Ghostty](https://ghostty.org/) ([repo](https://github.com/ghostty-org/ghostty))
Ghostty is a fast, feature-rich terminal emulator built for performance and customization.
- **Directory**: `ghostty/`

### [gopod](https://github.com/djensenius/gopod)
Gopod is a tool for making radio programs that are streaming online into podcasts.
- **Directory**: `gopod/`

### [herdr](https://herdr.dev)
Herdr is a terminal workspace manager for AI coding agents. Its config is a deliberate mirror of `tmux/tmux.conf` — same `Ctrl+a` prefix, same Catppuccin Mocha palette, and the same muscle memory — so switching between the two costs nothing.
- **Directory**: `herdr/`
- **Files**: `herdr/config.toml`, status and popup helpers in `herdr/scripts/`
- **Linking**: Herdr keeps live sockets, logs and session state in `~/.config/herdr`, and owns `~/.config/herdr/plugins` for its own managed checkouts, so the directory is *not* symlinked wholesale. The installers link `config.toml` and `scripts/` individually.

#### tmux → herdr keymap

| tmux | herdr | Provided by |
| --- | --- | --- |
| `prefix` = `^a` | `prefix` = `ctrl+a` | config |
| `prefix h/j/k/l` focus pane | same | config |
| `prefix ^h/^j/^k/^l` resize 10 | same | native `resize_pane_*` bindings (0.05 split-ratio delta) |
| `prefix ^u` / `^d` swap pane | same | `[[keys.command]]` → `herdr pane swap` |
| `prefix \|` / `\` / `%` split side by side | same, plus `prefix v` | `split_vertical` — Herdr names splits after the divider, so this is "vertical" where tmux calls it `-h` |
| `prefix -` / `_` / `"` split stacked | same | `split_horizontal` |
| `prefix q` kill pane | same (detach moves to `prefix d`) | config |
| `prefix p` / `n` previous/next window | same | config |
| `prefix 1..9` select window | same | config |
| `prefix (` / `)` previous/next session | `prefix ,` / `prefix .` previous/next workspace | config |
| — | `prefix ^g` remove worktree checkout (confirms first) | config |
| — | `prefix ^p` / `prefix ^n` previous/next agent | config |
| — | `prefix alt+1..9` focus agent | config |
| `prefix F1` / `^b` toggle status | `prefix b` / `prefix F1` toggle sidebar | config |
| `prefix \`` gotop | `prefix \`` btop | `[[keys.command]]` |
| `prefix m` man prompt | same | `herdr/scripts/herdr-man-popup.sh` |
| `prefix /` command prompt | same | `herdr/scripts/herdr-run-popup.sh` |
| outdated-package popup | `prefix Shift+i` or `cli-update` | `herdr/scripts/herdr-cli-update.sh` |
| `<C-h/j/k/l>` vim-tmux-navigator | same | [vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation) |
| tmux-sessionx (`prefix o`) | same | [herdr-navigator](https://github.com/thanhdat77/herdr-navigator) |
| tmux-floax (`prefix O`) | same | [herdr-floax](https://github.com/Tyru5/herdr-floax) |
| tmux-which-key (`prefix space`) | same | [herdr-command-palette](https://github.com/JanTvrdik/herdr-command-palette) |
| tmux-thumbs | `prefix y` | [herdr-pluck](https://github.com/rmarganti/herdr-pluck) |
| tmux-fzf-url (`prefix u`) | `prefix u` links, `prefix U` files | [termscope](https://github.com/iurysza/termscope) |
| tmux-yank, `set-clipboard on` | `copy_on_select` | config |
| catppuccin/tmux | `[theme] name = "catppuccin"` | config |

#### Desktop tab bar and status

The **desktop tab bar** is Herdr's own top row of tabs inside the full-width
terminal UI (as opposed to its narrow/mobile layout or the native tabs of
Ghostty, Rio or WezTerm). Since 0.8.2, its unused right edge can hold
right-aligned status entries.

`ui.tab_bar_right` shows Herdr's built-in `ZOOM` indicator plus
`herdr/scripts/herdr-status-report.sh --tab-bar`. The helper renders
`battery_hearts` and non-zero brew/npm/pi/pip/cargo/go/mise/herdr update counts from the
shared `tmux-outdated-packages` cache every five seconds. This replaces the old
dedicated `status` workspace and its custom sidebar metadata.

The package checks themselves remain asynchronous. Before showing update
actions, `cli-update` waits for a fresh result from every installed checker,
requires the poller's versioned successful-generation token, snapshots that
validated cache generation, and uses only the snapshot for display and
upgrades. Failed or timed-out checks do not advance the token, while a partially
written or newer generation cannot be mistaken for an all-clear or change the
package list after it is shown. Refresh requests remain pending until the poller
acknowledges a post-request generation, so an in-flight older cycle cannot
satisfy the updater. The tmux plugin owns an atomic startup lock, so tmux, the
updater and the launch agent can all start the poller without creating competing
workers. The plugin starts it whenever tmux runs; on macOS, the launch agent
below directly supervises it when Herdr is used on its own:

  ```bash
  mkdir -p ~/Library/LaunchAgents
  ln -sf ~/.dotfiles/herdr/launchd/dev.djensenius.herdr-status.plist ~/Library/LaunchAgents/
  launchctl bootout "gui/$(id -u)/dev.djensenius.herdr-status" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/dev.djensenius.herdr-status.plist
  ```

Tune the display with `HERDR_STATUS_HEARTS` and `HERDR_STATUS_MAX_AGE`; override
the shared poller path with `HERDR_STATUS_POLLER`. Run the helper with
`--tab-bar` to preview its exact output or `--ensure-poller` to repair a stopped
poller. Pi packages come from the Pi agent npm prefix
`${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/npm`, which is separate from
`npm outdated -g`; their update action runs `pi update --extensions`. Herdr
plugin counts come from `herdr plugin list` SHA comparisons, and the updater
reinstalls outdated plugins with `herdr plugin install owner/repo --yes`. The
Herdr helpers treat missing `pi`/`herdr` cache files as zero so they remain
compatible with older `tmux-outdated-packages` plugin checkouts.

tmux-speedtest stays tmux-only: it is on-demand rather than ambient, so it is
not polled into the Herdr tab bar.

#### Kitty graphics

`[experimental] kitty_graphics = true` turns on client-side Kitty graphics rendering, so image output (yazi previews, plots, `timg`) draws inside panes. It needs a Kitty-graphics-capable outer terminal — Ghostty, wezterm and Rio all qualify. Detach and reattach after enabling; the flag is negotiated when a client attaches.


#### Tab naming

Herdr's native tab naming is used as-is. `ui.prompt_new_tab_name = true` asks for a name when a tab is created, and `prefix T` renames later. The tmux equivalents — [tmux-contextual-window-name](https://github.com/djensenius/tmux-contextual-window-name) and [tmux-nerd-font-window-name](https://github.com/joshmedeski/tmux-nerd-font-window-name) — are **not** ported; the tmux config's Copilot title special-case is unnecessary here because Herdr detects agents natively.

#### Agent integrations

Herdr detects GitHub Copilot CLI automatically — the agent shows up in the Agent sidebar with `idle`/`working`/`blocked` state via screen-manifest detection, with no setup. This replaces the tmux config's Copilot window-title special-case.

The optional hook adds **native session identity**, which lets Herdr resume a Copilot pane with `copilot --resume=<id>` after a server restart:

```bash
mkdir -p "${COPILOT_HOME:-$HOME/.copilot}"
herdr integration install copilot
herdr integration status
```

It writes `~/.copilot/hooks/herdr-agent-state.sh` (or `$COPILOT_HOME`) and adds
a `SessionStart` entry to `~/.copilot/settings.json`. This is a one-time step;
`./install-agent-stack` creates the config directory and installs the
integration automatically when Copilot CLI is available. Undo with
`herdr integration uninstall copilot`.

The hook is not a state authority — Copilot's `idle`/`working`/`blocked` state always comes from screen detection, whether or not it is installed.

#### Pi + Herdr subagents

The optional Pi agent stack uses
[`pi-subagents`](https://github.com/nicobailon/pi-subagents) for delegation. A
coordinator can delegate read-only investigation to `scout`, implementation to
a `worker` (launched with `cwd` set to a persistent Git worktree the
coordinator creates, so its branch survives for review), and commit
review to the custom read-only `reviewer` profile. Foreground children stream
in the parent conversation; background children keep running in a detached
runner and show up in the FleetView and `/subagents-fleet`. Inside Herdr, the
parent pane reports active background work through Herdr's pane status:

```bash
./install-agent-stack
```

The installer requires system Git 2.45.0 or newer for `--no-lazy-fetch`
enforcement and checks it before making integration or extension changes.
Upgrade Git with Homebrew (`brew install git`) on macOS or the operating
system's package manager; Git is intentionally not managed by mise. The
installer uses the mise-managed Node, Pi, and Herdr binaries, installs the
Copilot Herdr integration when Copilot is available, copies the repository-owned
`review_git` extension into Pi's agent directory, copies the shared Catppuccin
footer config, copies the
`reviewer` and `council-gpt`/`council-claude`/`council-gemini` profiles into
`~/.pi/agent/agents/` (the reviewer loads `../extensions/reviewer-git.ts`
relative to itself), and installs `xbuild` into `~/.local/bin`.

The stack also keeps a small shared Pi config under `pi/agent-stack/` and
merges it into the user files instead of replacing them, so machine-local
settings such as `lastChangelogVersion`, existing `packages`, local MCP
servers, and other keys are preserved. Shared settings set the Pi defaults to
GitHub Copilot `gpt-5.5`, medium thinking, the Pi `system` theme, fullscreen
TUI mode, and Pi 1.0's `quietStartup: "header"` mode so launches keep the
version/key-hint header without the longer loaded-resource listing. Other Pi 1.0
features such as Radius sign-in, image generation from codemode, and custom MCP
OAuth metadata are account- or server-specific, so they are left for each user
or MCP server instead of being forced by the shared dotfiles config. The stack
also sets these builtin subagent model overrides:

| Agent | Model |
| --- | --- |
| `scout` | `github-copilot/gpt-5.4-mini` |
| `researcher` | `github-copilot/gemini-3.8-flash` |
| `worker` | `github-copilot/gpt-5.5` |
| `reviewer` | `github-copilot/claude-opus-5.5` |
| `oracle` | `github-copilot/claude-opus-5.5` |

Like Pi and Herdr (both `latest` in mise), `pi-subagents` is deliberately
unpinned: the installer installs `npm:pi-subagents` and runs
`pi update --extension npm:pi-subagents` on every re-run, so the extension
keeps pace with Herdr API changes. Other shared Pi packages are also unpinned
and installed only when absent from the `User packages:` section of `pi list`:
`npm:pi-catppuccin-footer`, `npm:@plannotator/pi-extension`,
`npm:pi-web-access`, `npm:pi-browser-harness`, `npm:pi-memctx`, and
`npm:@narumitw/pi-herdr`. The `pi-herdr` package
replaces Herdr's standalone Pi lifecycle integration and Pi's use of the
standalone global Herdr skill, so the installer removes
`~/.pi/agent/extensions/herdr-agent-state.ts`, any legacy
`~/.pi/agent/skills/herdr` link, and the canonical `~/.agents/skills/herdr`
skill. When Copilot CLI is installed, the installer first prepares valid,
version-matched Herdr guidance and then publishes it under
`${COPILOT_HOME:-~/.copilot}/skills/herdr` so Copilot keeps its skill without
making the duplicate visible to Pi. Copilot's Herdr lifecycle integration also
remains in place.

The `pi-subagents` extension config lives at
`~/.pi/agent/extensions/subagent/config.json`. The shared config keeps
FleetView enabled (`fleetView: true`) as the single under-editor view of
subagent work, turns off the duplicate async widget (`asyncWidget: false`), and
leaves inspector opening on the documented automatic policy (`authorityPolicy.inspectorOpen: "auto"`). The bundled inspector
dispatcher tries Herdr first, then Ghostty, then external providers, so Herdr is
the default inspector surface when Pi is running inside Herdr.

MCP servers are configured through Pi's built-in MCP config at
`~/.pi/agent/mcp.json` (or `$PI_CODING_AGENT_DIR/mcp.json`). The installer
merges in two stdio servers and preserves any other servers:

- `playwright`: `npx -y @playwright/mcp@latest --browser firefox`, described
  as browser automation and page inspection through Playwright using Firefox.
- `context7`: `npx -y @upstash/context7-mcp@latest`, described as current
  library documentation lookup through Context7.

On upgrade from the old `npm:pi-mcp-adapter` package, the installer copies any
servers from `~/.pi/agent/mcp-adapter.json` into the built-in `mcp.json` when
that can be done safely, then renames the legacy file to
`mcp-adapter.json.migrated` and removes the adapter package so Pi does not start
both MCP paths. Adapter-specific settings such as footer/status toggles are not
copied because built-in MCP does not read them; if a legacy server conflicts
with an existing built-in server, the built-in entry is kept and the old
configuration remains in the `.migrated` backup for manual review.

Built-in MCP exposes configured servers to Pi directly; run `/mcp` in Pi or
`pi mcp list` from the shell to check server availability. The shared footer
config (`pi/agent-stack/catppuccin-footer.json`) hides the `browser` and
`memctx` status items and drops the `git`, `gitDiff`, `lastTokens`, `cost` and
`time` sections; Herdr's sidebar already shows each workspace's branch.
Herdr's agent sidebar includes `state_text`, so while background subagents run
the Pi pane shows the label pi-subagents publishes (workflow label, agent name
or active count, with `⚠` when a subagent needs attention).
In Pi itself, the repository-owned `subagent-status.ts` extension adds a
footer status item such as `⚙ 3 subagents` (or `⚠ 3 subagents` when one needs
you) while background subagents run, so a coordinator shown as `idle` is
visibly waiting on subagent work. It uses only pi-subagents' public events and
event-bus RPC, and is tested by `pi/agent-stack/tests/subagent-status.test.ts`
(`node pi/agent-stack/tests/subagent-status.test.ts`).

Playwright needs its own Firefox build. Because the server runs as
`@latest`, a Playwright update can require a newer build, so re-run
`npx playwright install firefox` whenever the MCP server reports a missing or
outdated browser. To use Edge instead, change the Playwright
server args from `--browser firefox` to `--browser msedge`. GitHub MCP is not
configured here because `gh` already covers that workflow.

The agent-stack installer does not create the Herdr config links; set up Herdr
first (for example with `./install-mac --only links`, or see *Special setup for
Herdr*) so pane helpers and plugin configuration are in place.

The reviewer has no shell tool. Its `review_git` capability resolves the Git
worktree from the reviewer's current directory and exposes only bounded,
read-only `show`, `diff`, `log`, and `rev-parse` operations over committed
objects. Commit inputs must be full 40-character hexadecimal IDs. `show`,
`diff`, and `log` return one bounded page at a time with total-page and
continuation metadata, and the reviewer must retrieve every page before
approval. Page windows are counted in decoded Unicode code points; invalid or
incomplete UTF-8 bytes become `U+FFFD`, while valid multibyte characters are
never split between pages. Paths are validated repository-relative literals,
lazy fetching is disabled both globally and through the environment, inherited
`GIT_*` configuration injection is scrubbed, system Git configuration is
disabled, and the model cannot supply Git flags, environment, argv, or another
repository path.

The stack previously used `maxedapps/pi-subagents-herdr`, which is
incompatible with Herdr 0.9.1 (`agent.start` now requires an agent `kind` and
an existing pane). The installer removes that package and its old profiles from
`~/.pi/agent/herdr-subagents/` automatically, and replaces any version-pinned
`npm:pi-subagents@x.y.z` entry with the unpinned package.

To enable the coordinator workflow in a repository, copy or merge the template:

```bash
cp ~/.dotfiles/pi/agent-stack/templates/AGENTS.md ./AGENTS.md
```

The template is deliberately opt-in because it requires a scout before
implementation, worktree workers, reviewer approval before opening a PR, PR-only
source changes, task tracking in [Backlog.md](https://github.com/MrLesk/Backlog.md),
and pushed task branches. Set up Backlog.md with:

```bash
brew install backlog-md
backlog init --backlog-dir .backlog
backlog config set autoCommit true
backlog config set checkActiveBranches true
backlog agents --update-instructions
mkdir -p .github/instructions
cp ~/.dotfiles/pi/agent-stack/templates/backlog.instructions.md .github/instructions/
```

Also include this two-line section in the repository's
`.github/copilot-instructions.md`:

```markdown
## Backlog.md files
Copilot code review must not review or comment on Backlog.md task files; `.github/instructions/backlog.instructions.md` owns the path rule.
```

Land these setup files through a PR before relying on the workflow; Copilot reads
instructions from the base branch. Enable automatic Copilot code review and a
ruleset or branch protection that requires CI before merge.

Optionally mirror `.backlog/` into a GitHub Project with
[backlog-sync](https://github.com/djensenius/backlog-sync). The template's
workflow section describes the PR, backlog board, and `inbox` triage rules.

On macOS, `xbuild` is a drop-in `xcodebuild` wrapper that serializes builds
with the native `lockf` utility. Test runs default to two parallel workers and
shut down simulators afterward. Set `XBUILD_KEEP_SIMS=1` to keep them running,
or `XBUILD_DERIVED_DATA_ROOT` to put per-checkout DerivedData elsewhere.

#### Plugin prerequisites

Install these before the plugins, since they are needed at build time or at
runtime and a missing one either aborts the install or makes the bound key fail
silently:

| Requirement | Needed by |
| --- | --- |
| `cargo` (Rust toolchain) | `herdr-floax`, `herdr-navigator`, `herdr-plugin-renamer` — built from source |
| `node` 20+ and `npm` | `agent-slack-notify`, `heeler` |
| `python3` (3.11+) | `termscope`, `kuwa72.focus-attention` |
| `jq` | `vim-herdr-navigation`, `herdr-floax`, `jt.command-palette` |
| `fzf` | `jt.command-palette` |
| `fd` | `termscope` file picker |
| [Television](https://github.com/alexpasmantier/television) 0.15+ | `termscope` — its build step installs this **via Homebrew**, so `brew` must be on `PATH` or the plugin install fails |
| Clipboard command (`pbcopy` on macOS, `wl-copy` on Wayland, `xclip`/`xsel` on X11) | `herdr-pluck` |
| OpenSSH server with host keys | `heeler` pairing (`Remote Login` on macOS; run `sudo ssh-keygen -A` if host keys are missing) |

`install.sh` does **not** install Herdr itself. Once `herdr` is on `PATH`, re-running
`./install.sh` installs or refreshes every plugin (`install` doubles as the update
path, so a rerun pulls the latest revision). Without `herdr`, the script logs a warning
and skips the plugin phase entirely — which is what happens in a fresh Codespace. To do
it by hand:

```bash
herdr plugin install paulbkim-dev/vim-herdr-navigation --yes
herdr plugin install JanTvrdik/herdr-command-palette --yes
herdr plugin install rmarganti/herdr-pluck --yes
herdr plugin install Tyru5/herdr-floax --yes
herdr plugin install thanhdat77/herdr-navigator --yes
herdr plugin install iurysza/termscope --yes
herdr plugin install wyattjoh/herdr-plugin-renamer --yes
herdr plugin install kuwa72/herdr-focus-attention --yes
herdr plugin install juninaba/herdr-slack-notify --yes
herdr plugin install ZingerLittleBee/Heeler/plugin --yes
```

### [k9s](https://k9scli.io) ([repo](https://github.com/derailed/k9s))
K9s is a terminal UI to interact with your Kubernetes clusters.
- **Directory**: `k9s/`

### [Kitty](https://sw.kovidgoyal.net/kitty) ([repo](https://github.com/kovidgoyal/kitty))
Kitty is a GPU-accelerated terminal emulator, configured to match Rio and WezTerm with Monaspace fonts and the OLED Catppuccin Mocha theme.
- **Directory**: `kitty/`
- **Option key**: Left Option acts as Alt so herdr's `prefix alt+1..9` agent-focus shortcuts work, while right Option keeps macOS Unicode composition.
- **macOS icon**: `kitty.app.icns`, adapted from the MIT-licensed Icon Composer design in [sodapopcan/kitty-icon](https://github.com/sodapopcan/kitty-icon) with an optical inset for Golden Gate's Dock and app switcher; its license is in `kitty-icon.LICENSE`

### [lazygit](https://github.com/jesseduffield/lazygit)
Lazygit is a simple terminal UI for git commands with keyboard shortcuts.
- **Installation**: Downloaded binary to `/usr/local/bin`

### [NeoVim](https://neovim.io) ([repo](https://github.com/neovim/neovim))
NeoVim is a hyperextensible Vim-based text editor.
- **Directory**: `nvim/`
- **See**: [nvim/README.md](nvim/README.md) for comprehensive plugin documentation

### [pay-respects](https://github.com/LudwigZeller/pay-respects)
Pay-respects is a modern replacement for thefuck, fixing command line errors with AI assistance.
- **Installation**: Via cargo

### [ripgrep](https://github.com/BurntSushi/ripgrep)
Ripgrep is a line-oriented search tool that recursively searches directories for a regex pattern.
- **Installation**: Via cargo

### [rio](https://rioterm.com) ([repo](https://github.com/raphamorim/rio))
Rio is a GPU-accelerated terminal emulator, configured here with the Catppuccin Mocha theme.
- **Directory**: `rio/`
- **Option key**: `option-as-alt = "left"` so `alt` chords (e.g. herdr's `prefix alt+1..9` agent focus) reach the app. This matches wezterm's default, where left Option is Alt and right Option still composes Unicode. Ghostty needs no setting on U.S. layouts, but its default maps *both* Option keys to Alt — set `macos-option-as-alt = left` there if you want right Option to keep composing.

### [Starship](https://starship.rs) ([repo](https://github.com/starship/starship))
Starship is a cross-shell prompt that displays information about the current directory, git status, and more.
- **File**: `starship.toml`

### [tmux](https://github.com/tmux/tmux/wiki) ([repo](https://github.com/tmux/tmux))
Tmux is a terminal multiplexer that allows multiple terminal sessions to be accessed and controlled from a single screen.
- **Directory**: `tmux/`
- **Features**: Catppuccin Mocha theme, vim-style navigation, floating windows, session management
- **Battery Status**: Uses [battery_hearts](https://github.com/djensenius/battery_hearts) plugin to display battery level with heart icons in the status bar

#### Installing battery_hearts
The battery_hearts tool displays battery status using heart icons and is integrated into the tmux status bar. Install it using one of these methods:

**From crates.io (Recommended):**
```bash
cargo install battery_hearts
```

**From releases:**
```bash
# Download the latest binary for your platform from:
# https://github.com/djensenius/battery_hearts/releases
chmod +x battery_hearts-*
# Move to PATH, e.g., /usr/local/bin/
```

**From source:**
```bash
git clone https://github.com/djensenius/battery_hearts.git
cd battery_hearts
cargo build --release
# Copy ./target/release/battery_hearts to your PATH
```

Once installed, the tmux configuration will automatically use it to display battery status with heart icons (❤️ 🧡 🤍) in the status bar.

### [tmuxinator](https://github.com/tmuxinator/tmuxinator)
Tmuxinator is a tool to manage complex tmux sessions easily.
- **Directory**: `tmuxinator/`

### [vale](https://vale.sh) ([repo](https://github.com/errata-ai/vale))
Vale is a syntax-aware linter for prose built with speed and extensibility in mind.
- **File**: `vale.ini`

### [yazi](https://github.com/yazi-shell/yazi)
Yazi is a terminal file manager.
- **Directory**: `yazi/`


### [zoxide](https://github.com/ajeetdsouza/zoxide)
Zoxide is a smarter cd command that learns your habits and jumps to frequently used directories.
- **Installation**: Via cargo

## Codespaces `install.sh` Script Summary

The `install.sh` script is designed to set up and configure a development environment, particularly for use in GitHub Codespaces. It performs the following tasks:

### 1. Link Configuration Files

- Creates necessary directories and creates symbolic links for various configuration files:
  - `tmux.conf`
  - `gitconfig`
  - `fish`
  - `starship.toml`
  - `nvim`
  - `bat`
  - `vale.ini`
  - `prettierrc.json`
  - `gitmux.conf`
  - `tmuxinator`
  - `neofetch`
  - `atuin`
  - `yazi`
  - `bottom`
  - `kitty`
  - `rio`
  - `herdr/config.toml`, `herdr/scripts`

- If running within a GitHub Codespace, it links executables (e.g., `rubocop`, `srb`, `bundle`, `solargraph`, `safe-ruby`) to `/usr/local/bin` and updates locale settings.

### 2. Install Software

- Installs various software packages required for the development environment, including:
  - `build-essential`
  - `python3-venv`
  - `socat`
  - `ncat`
  - `ruby-dev`
  - `jq`
  - `pay-respects` (replacement for thefuck)
  - `tmux`
  - `libfuse2`
  - `fuse`
  - `software-properties-common`
  - `most`

- Removes potentially conflicting packages (`bat`, `ripgrep`).

- Installs additional tools via `curl`, `wget`, `cargo`, `go`, `gem`, and `npm`:
  - `starship`
  - `delta`
  - `protobuf`
  - `eza`
  - `zoxide`
  - `ripgrep`
  - `fd-find`
  - `bat`
  - `atuin`
  - `gitmux`
  - `tmuxinator`
  - `neovim-ruby-host`
  - `prettierd`
  - `yaml-language-server`
  - `vscode-langservers-extracted`
  - `eslint_d`
  - `prettier`
  - `tree-sitter`
  - `neovim`
  - `fzf`
  - `lazygit`

### 3. Setup Software

- Logs into `atuin` using provided credentials.
- Installs `tmux` plugins.
- Synchronizes and installs `nvim` plugins.
- If running within a GitHub Codespace
  - Changes the default shell to `fish` for the `vscode` user.
  - Checks the status of the repository.

### 4. Logging

- Logs the progress of file linking, software installation, and software setup to `~/install.log`.

---

This script automates the setup process to ensure a consistent and efficient development environment, particularly optimized for GitHub Codespaces.
