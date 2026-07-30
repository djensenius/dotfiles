# Raspberry Pi setup

One command provisions a Raspberry Pi with these dotfiles and the whole
command-line toolchain:

```bash
git clone https://github.com/djensenius/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install-pi
```

It is safe to re-run — every step is idempotent, so `git pull && ./install-pi`
is the update path.

## Requirements

- **64-bit Raspberry Pi OS (`arm64`)**, Lite or Desktop, on a Pi 4 or 5.
  Several tools in [`mise.toml`](mise.toml) publish `aarch64` Linux binaries
  only, so 32-bit `armhf` cannot reproduce the set. The script warns and keeps
  going if it detects another architecture.
- A user with `sudo`, or run it as root. The script detects which it is and
  only escalates for the steps that need it (apt, `/etc/shells`, `chsh`);
  everything else runs as you, so nothing in `~` ends up owned by root. Run
  through `sudo`, it provisions `$SUDO_USER`'s account rather than root's.
- Network access. mise downloads prebuilt binaries instead of building them,
  so the toolchain is minutes rather than the hours a source build would take.
  The exceptions are the plugins: `tmux-thumbs` and `tmux-floax` (step 5)
  cargo-build, as do the herdr marketplace plugins in step 7 that publish no
  arm64 binary — `herdr-floax`, `herdr-navigator` and `herdr-pluck` at the time
  of writing.
- **A GitHub account.** mise fetches most tools through its aqua/github
  backends, which call `api.github.com`. Unauthenticated that is 60 requests an
  hour for your whole IP, so step 4 fails with `403 rate limit exceeded`
  part-way through. You do not have to do anything up front: if the script
  finds no token it installs the `gh` CLI from GitHub's apt repository and
  offers to run `gh auth login --web`, which prints a one-time code to enter on
  another machine. The token lands in `~/.config/gh/hosts.yml` (a real file —
  only `gh/config.yml` is symlinked into this repo) and is reused on later
  runs.

  To skip the prompt, bring your own token from
  <https://github.com/settings/tokens> — **no scopes are required**, it only
  reads public releases:

  ```bash
  GITHUB_TOKEN=ghp_... ./install-pi
  ```

  `GH_TOKEN` works too. Under `sudo`, use `sudo -E`, or sudo strips the
  variable before the script sees it. Re-running after a rate-limit failure is
  safe: already-installed tools are skipped.

## What it does

| # | Step | Notes |
| --- | --- | --- |
| 1 | apt packages | `git`, `build-essential`, `python3`, `btop`, `tmuxinator`, and friends. Falls back to installing one by one if a package is missing on your release. Generates a UTF-8 locale if the image has none. |
| 2 | mise | Installed from [its own apt repository](https://mise.jdx.dev), keyring and all. With `--skip-apt` it falls back to `https://mise.run`. |
| 3 | Symlinks | Links this repo into `~/.config` (fish, nvim, tmux, starship, atuin, bat, bottom, btop, delta, eza, fastfetch, yazi, zellij, tmuxinator, gh, gh-dash, herdr) plus `~/.gitconfig` and friends. Anything already there is moved to `~/.dotfiles-backup/<timestamp>/`, under its path relative to `~`, first. |
| 4 | Tools | Copies [`mise.toml`](mise.toml) to `~/.config/mise/config.toml`, trusts it, and runs `mise install`. Resolves a GitHub token first (env, `gh`, or an offered `gh auth login`) so the downloads are not rate-limited. |
| 5 | tmux plugins | Clones tpm and installs the plugin set. `tmux-thumbs` and `tmux-floax` build with cargo, which is why the manifest includes rust. |
| 6 | Neovim | `nvim --headless "+Lazy! sync" +qa`. |
| 7 | herdr plugins | The same marketplace plugins `install.sh` installs, including its removal of the legacy `herdr-picker-plus` id. |

Progress goes to the terminal; full command output goes to `~/install-pi.log`
(override with `INSTALL_PI_LOG`). `--dry-run` writes no log at all — every line
it would contain is already on the terminal — so previewing leaves nothing
behind, including the real log.

## Options

```text
--skip-apt      No package installs, and mise comes from mise.run instead
--skip-mise     Leave mise and ~/.config/mise/config.toml alone
--skip-links    No ~/.config symlinks
--skip-tmux     No tmux plugins
--skip-nvim     No neovim plugin sync
--skip-herdr    No herdr plugins
--fish-shell    Make the mise-managed fish the login shell (chsh)
--force         Overwrite existing configs instead of backing them up
--dry-run       Print every action without doing it
--yes, -y       No confirmation prompt
--help, -h      Usage
```

## Making fish the login shell

Not done by default, because a mise-managed fish lives under `~` rather than
`/usr/bin`:

```bash
./install-pi --fish-shell
```

That appends the path to `/etc/shells` and runs `chsh` as root against your
account. **Open a second SSH
session and confirm it works before closing the first** — a broken login shell
also breaks `ssh host <command>`, which is awkward on a headless Pi. The path
survives `mise upgrade`, because `latest` resolves through a symlink mise
repoints at each release. If you would rather not couple your login shell to
mise, `sudo apt install fish` gives you an older fish at `/usr/bin/fish`.

## Afterwards

- Open a new shell so mise's shims are on `PATH`.
- `atuin login -u <user>` once, to sync shell history.
- `gh auth login`, if you want the GitHub CLI and gh-dash.

## Relationship to install.sh

[`install.sh`](../install.sh) provisions GitHub Codespaces: it assumes a
throwaway container, installs via cargo/npm/gem, and parallelises aggressively.
`install-pi` targets a long-lived machine you SSH into: it prefers mise
binaries over compiling on a Pi's CPU, backs up rather than deletes what it
finds, and can be re-run to update.

[`mise.toml`](mise.toml) here is the Pi tool manifest and is unrelated to
[`../mise/config.toml`](../mise/config.toml), which is the workstation set
(go, ruby, python, kubectl, npm packages) and would be a long, largely
source-built install on a Pi. It started as Telephone-Booth's
`packaging/raspberry-pi/mise.toml`, with the extra tools these dotfiles assume
(zoxide, fzf, ripgrep, fd, node, rust).
