#!/usr/bin/env bash
# Raspberry Pi provisioning: apt packages, mise + tools, dotfiles symlinks,
# tmux/neovim/herdr plugins. Run it with ../install-pi from a clone of this
# repo.
#
# Safe to re-run: every step is idempotent and skips work already done.

set -euo pipefail

PI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$PI_DIR/.." && pwd)"
LOG_FILE="${INSTALL_PI_LOG:-$HOME/install-pi.log}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

DO_APT=true
DO_MISE=true
DO_LINKS=true
DO_TMUX=true
DO_NVIM=true
DO_HERDR=true
SET_FISH_SHELL=false
DRY_RUN=false
ASSUME_YES=false
FORCE=false

APT_PACKAGES=(
    ca-certificates
    curl
    wget
    gpg
    git
    git-lfs
    unzip
    zip
    xz-utils
    tar
    rsync
    less
    locales
    build-essential
    pkg-config
    libssl-dev
    python3
    python3-pip
    python3-venv
    tmuxinator
)

# ---------------------------------------------------------------- output ----

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RESET=$'\033[0m'
else
    C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_RESET=''
fi

log()  { printf '%s\n' "$*"; printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$LOG_FILE"; }
step() { printf '\n%s==> %s%s\n' "$C_BOLD" "$*" "$C_RESET"; printf '\n[%s] ==> %s\n' "$(date '+%F %T')" "$*" >>"$LOG_FILE"; }
ok()   { log "${C_GREEN}✓${C_RESET} $*"; }
skip() { log "${C_DIM}·${C_RESET} $*"; }
warn() { log "${C_YELLOW}⚠${C_RESET} $*"; }
die()  { log "${C_RED}✗${C_RESET} $*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

show_help() {
    cat <<'EOF'
install-pi — provision a Raspberry Pi with these dotfiles and tools

Usage: ./install-pi [OPTIONS]

Runs, in order:
  1. apt packages (git, build tools, python, ...)
  2. mise, from its own apt repository
  3. dotfiles symlinks into ~/.config
  4. pi/mise.toml -> ~/.config/mise/config.toml, then `mise install`
  5. tmux plugin manager + plugins
  6. neovim plugin sync (headless)
  7. herdr marketplace plugins

Options:
  --skip-apt        Do not touch apt (no package installs, no mise repo)
  --skip-mise       Do not install mise or its tool manifest
  --skip-links      Do not create ~/.config symlinks
  --skip-tmux       Do not install tmux plugins
  --skip-nvim       Do not sync neovim plugins
  --skip-herdr      Do not install herdr plugins
  --fish-shell      Make the mise-managed fish your login shell (chsh)
  --force           Replace existing config files instead of backing them up
  --dry-run         Print what would run without changing anything
  --yes, -y         Do not prompt for confirmation
  --help, -h        Show this help

Environment:
  INSTALL_PI_LOG    Log file path (default: ~/install-pi.log)

Everything is idempotent — re-run it after `git pull` to pick up changes.
EOF
}

# ------------------------------------------------------------ privileges ----

SUDO=""

setup_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        SUDO=""
        skip "Running as root; sudo not needed"
        return
    fi
    have sudo || die "Not root and sudo is not installed. Re-run as root, or install sudo."
    SUDO="sudo"
    if sudo -n true 2>/dev/null; then
        ok "sudo available without a password prompt"
    else
        log "sudo needs your password for the apt steps."
        $DRY_RUN || sudo -v || die "Could not obtain sudo privileges"
    fi
}

# Run a command as root (or directly, when already root).
as_root() {
    if $DRY_RUN; then
        log "${C_DIM}[dry-run] ${SUDO:+sudo }$*${C_RESET}"
        return 0
    fi
    if [ -n "$SUDO" ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# apt-get as root, never prompting for interactive config.
apt_get() {
    as_root env DEBIAN_FRONTEND=noninteractive apt-get "$@"
}

# Run a command as the current user.
as_user() {
    if $DRY_RUN; then
        log "${C_DIM}[dry-run] $*${C_RESET}"
        return 0
    fi
    "$@"
}

# ---------------------------------------------------------------- checks ----

preflight() {
    step "Preflight"

    [ "$(uname -s)" = "Linux" ] ||
        die "install-pi targets Raspberry Pi OS / Debian. On macOS use the README's manual steps."

    if $DO_APT; then
        have apt-get || die "apt-get not found — this script only supports Debian-based systems."
    fi

    local arch
    arch="$(uname -m)"
    case "$arch" in
        aarch64|arm64) ok "Architecture: $arch" ;;
        *) warn "Architecture is $arch, not aarch64. Several tools in pi/mise.toml publish aarch64 binaries only and will fail to install." ;;
    esac

    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        ok "OS: $(. /etc/os-release && echo "$PRETTY_NAME")"
    fi

    [ -d "$DOTFILES_DIR/fish" ] ||
        die "$DOTFILES_DIR does not look like the dotfiles repo (no fish/ directory)."
    ok "Dotfiles: $DOTFILES_DIR"
    ok "Log: $LOG_FILE"

    if ! $ASSUME_YES && ! $DRY_RUN && [ -t 0 ]; then
        printf '\nProceed? [Y/n] '
        local reply
        read -r reply
        case "$reply" in
            [nN]*) die "Aborted." ;;
        esac
    fi
}

# ------------------------------------------------------------------ apt ------

install_apt_packages() {
    $DO_APT || { skip "Skipping apt packages (--skip-apt)"; return; }
    step "Installing apt packages"

    apt_get update

    # One batch is much faster, but a single unavailable package (tmuxinator is
    # not in every Debian release) would abort the lot — so fall back to
    # installing individually and only warn about what is genuinely missing.
    if apt_get install -y --no-install-recommends "${APT_PACKAGES[@]}"; then
        ok "Installed ${#APT_PACKAGES[@]} apt packages"
    else
        warn "Batch install failed; retrying package by package"
        local pkg failed=()
        for pkg in "${APT_PACKAGES[@]}"; do
            apt_get install -y --no-install-recommends "$pkg" >>"$LOG_FILE" 2>&1 ||
                failed+=("$pkg")
        done
        if [ ${#failed[@]} -gt 0 ]; then
            warn "Unavailable on this release: ${failed[*]}"
        fi
        ok "Installed remaining apt packages"
    fi

    ensure_locale
}

ensure_locale() {
    # fish, neovim and the Catppuccin/nerd-font glyphs all assume a UTF-8
    # locale; Raspberry Pi OS Lite ships without one generated.
    if locale -a 2>/dev/null | grep -qiE '^(en_US\.utf-?8|C\.utf-?8)$'; then
        skip "UTF-8 locale already available"
        return
    fi
    log "Generating en_US.UTF-8 locale"
    as_root sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    as_root locale-gen
    as_root update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    ok "Locale set to en_US.UTF-8"
}

# ----------------------------------------------------------------- mise ------

install_mise() {
    $DO_MISE || { skip "Skipping mise (--skip-mise)"; return; }
    step "Installing mise"

    if have mise; then
        ok "mise already installed ($(mise --version 2>/dev/null | head -1))"
        return
    fi

    if ! $DO_APT; then
        # --skip-apt rules out mise's apt repository, so use its own installer.
        log "Installing mise via https://mise.run (apt steps skipped)"
        as_user bash -c 'curl -fsSL https://mise.run | sh'
        export PATH="$HOME/.local/bin:$PATH"
        if ! have mise && ! $DRY_RUN; then
            die "mise install failed"
        fi
        ok "mise installed to ~/.local/bin/mise"
        return
    fi

    as_root install -dm 755 /etc/apt/keyrings
    if [ ! -s /etc/apt/keyrings/mise-archive-keyring.gpg ]; then
        if $DRY_RUN; then
            log "${C_DIM}[dry-run] fetch mise gpg key -> /etc/apt/keyrings/mise-archive-keyring.gpg${C_RESET}"
        else
            wget -qO - https://mise.jdx.dev/gpg-key.pub |
                gpg --dearmor |
                as_root tee /etc/apt/keyrings/mise-archive-keyring.gpg >/dev/null
        fi
    fi

    local arch line
    arch="$(dpkg --print-architecture 2>/dev/null || echo arm64)"
    line="deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=$arch] https://mise.jdx.dev/deb stable main"
    if $DRY_RUN; then
        log "${C_DIM}[dry-run] write /etc/apt/sources.list.d/mise.list${C_RESET}"
    else
        printf '%s\n' "$line" | as_root tee /etc/apt/sources.list.d/mise.list >/dev/null
    fi

    apt_get update
    apt_get install -y mise
    ok "mise installed from its apt repository"
}

install_mise_tools() {
    $DO_MISE || { skip "Skipping mise tools (--skip-mise)"; return; }
    step "Installing tools with mise"

    if ! have mise && ! $DRY_RUN; then
        warn "mise not on PATH; skipping tool install"
        return 0
    fi

    as_user mkdir -p "$HOME/.config/mise"
    local mise_config="$HOME/.config/mise/config.toml"
    # A copy, not a symlink: mise treats a config resolved through a symlink
    # into the repo as non-global. That also means an existing symlink has to
    # go first, or cp would follow it and overwrite the file it points at
    # (mise/config.toml in this repo, for anyone who linked the workstation
    # manifest there).
    if [ -e "$mise_config" ] || [ -L "$mise_config" ]; then
        if ! $FORCE && ! cmp -s "$PI_DIR/mise.toml" "$mise_config" 2>/dev/null; then
            as_user mkdir -p "$BACKUP_DIR"
            as_user cp -P "$mise_config" "$BACKUP_DIR/mise-config.toml"
            warn "Backed up existing ~/.config/mise/config.toml to ${BACKUP_DIR/#$HOME/\~}"
        fi
        as_user rm -f "$mise_config"
    fi
    as_user cp "$PI_DIR/mise.toml" "$mise_config"
    ok "Wrote ~/.config/mise/config.toml from pi/mise.toml"

    as_user mise trust "$mise_config"
    log "Running mise install (downloads prebuilt binaries; a few minutes on a Pi)"
    as_user mise install
    ok "mise tools installed"

    # Later phases (tmux plugins, nvim sync, herdr) need the freshly installed
    # binaries in this shell's PATH.
    local shims="$HOME/.local/share/mise/shims"
    if [ -d "$shims" ]; then
        export PATH="$shims:$PATH"
    fi
    return 0
}

# ---------------------------------------------------------------- links ------

# link_config <repo-relative source> <absolute target>
link_config() {
    local src="$DOTFILES_DIR/$1" target="$2"

    if [ ! -e "$src" ]; then
        warn "Missing in repo, not linked: $1"
        return
    fi

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        skip "Already linked: ${target/#$HOME/\~}"
        return
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        if $FORCE; then
            as_user rm -rf "$target"
        else
            as_user mkdir -p "$BACKUP_DIR"
            as_user mv "$target" "$BACKUP_DIR/$(basename "$target")"
            warn "Backed up existing ${target/#$HOME/\~} to ${BACKUP_DIR/#$HOME/\~}"
        fi
    fi

    as_user mkdir -p "$(dirname "$target")"
    # -n so a re-run replaces a symlink rather than dereferencing it and
    # creating a nested copy inside the target directory.
    as_user ln -sfn "$src" "$target"
    ok "Linked ${target/#$HOME/\~} -> $1"
}

link_configs() {
    $DO_LINKS || { skip "Skipping symlinks (--skip-links)"; return; }
    step "Linking config files"

    as_user mkdir -p "$HOME/.config" "$HOME/.local/bin"

    link_config gitconfig "$HOME/.gitconfig"
    link_config gitignore_local "$HOME/.gitignore_local"
    link_config vale.ini "$HOME/.vale.ini"

    link_config fish "$HOME/.config/fish"
    link_config nvim "$HOME/.config/nvim"
    link_config tmux "$HOME/.config/tmux"
    link_config starship.toml "$HOME/.config/starship.toml"

    link_config atuin "$HOME/.config/atuin"
    link_config bat "$HOME/.config/bat"
    link_config bottom "$HOME/.config/bottom"
    link_config btop "$HOME/.config/btop"
    link_config delta "$HOME/.config/delta"
    link_config eza "$HOME/.config/eza"
    link_config fastfetch "$HOME/.config/fastfetch"
    link_config yazi "$HOME/.config/yazi"
    link_config zellij "$HOME/.config/zellij"
    link_config tmuxinator "$HOME/.config/tmuxinator"
    link_config gitmux.conf "$HOME/.config/gitmux.conf"
    link_config prettierrc.json "$HOME/.config/prettierrc.json"

    link_config gh/config.yml "$HOME/.config/gh/config.yml"
    link_config gh-dash/config.yml "$HOME/.config/gh-dash/config.yml"

    # herdr keeps live sockets, logs and its own plugin checkouts in
    # ~/.config/herdr, so the directory itself must stay real — link only the
    # pieces this repo owns.
    as_user mkdir -p "$HOME/.config/herdr"
    link_config herdr/config.toml "$HOME/.config/herdr/config.toml"
    link_config herdr/scripts "$HOME/.config/herdr/scripts"

    # tmux.conf references this by name, so it has to resolve on PATH.
    link_config scripts/tmux-background-install-indicator.sh \
        "$HOME/.local/bin/tmux-background-install-indicator.sh"
}

# --------------------------------------------------------------- plugins -----

install_tmux_plugins() {
    $DO_TMUX || { skip "Skipping tmux plugins (--skip-tmux)"; return; }
    step "Setting up tmux plugins"

    local tpm="$HOME/.config/tmux/plugins/tpm"
    if [ -d "$tpm/.git" ]; then
        skip "tpm already cloned"
    else
        as_user mkdir -p "$HOME/.config/tmux/plugins"
        as_user git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm"
        ok "Cloned tpm"
    fi

    # Some plugins still look in the legacy ~/.tmux location.
    as_user mkdir -p "$HOME/.tmux/plugins"
    if [ ! -e "$HOME/.tmux/plugins/tpm" ]; then
        as_user ln -sfn "$tpm" "$HOME/.tmux/plugins/tpm"
    fi

    if ! have tmux && ! $DRY_RUN; then
        warn "tmux not on PATH; skipping plugin install (re-run after opening a new shell)"
        return
    fi

    # tmux-thumbs and tmux-floax build with cargo, so this needs the mise rust.
    log "Installing tmux plugins (a couple of these build from source)"
    as_user "$tpm/bin/install_plugins" >>"$LOG_FILE" 2>&1 ||
        warn "Some tmux plugins failed to install — see $LOG_FILE"
    ok "tmux plugins installed"
}

sync_neovim() {
    $DO_NVIM || { skip "Skipping neovim sync (--skip-nvim)"; return; }
    step "Syncing neovim plugins"

    if ! have nvim && ! $DRY_RUN; then
        warn "nvim not on PATH; skipping (run 'nvim' once to let lazy.nvim bootstrap)"
        return
    fi

    log "Running lazy.nvim sync headless (a few minutes on a first run)"
    as_user nvim --headless "+Lazy! sync" +qa >>"$LOG_FILE" 2>&1 ||
        warn "Neovim plugin sync reported errors — see $LOG_FILE"
    ok "Neovim plugins synced"
}

install_herdr_plugins() {
    $DO_HERDR || { skip "Skipping herdr plugins (--skip-herdr)"; return; }
    step "Installing herdr plugins"

    if ! have herdr && ! $DRY_RUN; then
        warn "herdr not on PATH; skipping plugin install"
        return
    fi

    local plugin
    for plugin in \
        paulbkim-dev/vim-herdr-navigation \
        JanTvrdik/herdr-command-palette \
        rmarganti/herdr-pluck \
        Tyru5/herdr-floax \
        thanhdat77/herdr-navigator \
        iurysza/termscope; do
        as_user herdr plugin install "$plugin" --yes >>"$LOG_FILE" 2>&1 ||
            warn "Failed to install herdr plugin $plugin — see $LOG_FILE"
    done
    ok "herdr plugins installed"
}

# ------------------------------------------------------------ login shell ----

set_login_shell() {
    $SET_FISH_SHELL || return 0
    step "Making fish the login shell"

    local fish_path
    if $DRY_RUN; then
        fish_path="$HOME/.local/share/mise/installs/fish/latest/bin/fish"
    else
        fish_path="$(mise which fish 2>/dev/null || command -v fish || true)"
        if [ -z "$fish_path" ]; then
            warn "fish not found; not changing the login shell"
            return 0
        fi
    fi

    if [ "${SHELL:-}" = "$fish_path" ]; then
        skip "fish is already the login shell"
        return
    fi

    if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
        printf '%s\n' "$fish_path" | as_root tee -a /etc/shells >/dev/null
    fi
    as_user chsh -s "$fish_path" ||
        warn "chsh failed; run: chsh -s $fish_path"

    warn "Your login shell now depends on mise. Open a second SSH session and confirm it works before closing this one."
    ok "Login shell set to $fish_path"
}

# ----------------------------------------------------------------- main ------

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --skip-apt)    DO_APT=false ;;
            --skip-mise)   DO_MISE=false ;;
            --skip-links)  DO_LINKS=false ;;
            --skip-tmux)   DO_TMUX=false ;;
            --skip-nvim)   DO_NVIM=false ;;
            --skip-herdr)  DO_HERDR=false ;;
            --fish-shell)  SET_FISH_SHELL=true ;;
            --force)       FORCE=true ;;
            --dry-run)     DRY_RUN=true ;;
            --yes|-y)      ASSUME_YES=true ;;
            --help|-h)     show_help; exit 0 ;;
            *) printf 'Unknown option: %s\nUse --help for usage.\n' "$1" >&2; exit 1 ;;
        esac
        shift
    done

    : >"$LOG_FILE"
    local start_time
    start_time=$(date +%s)

    printf '%s🍓 install-pi — Raspberry Pi dotfiles setup%s\n' "$C_BOLD" "$C_RESET"
    if $DRY_RUN; then
        log "${C_YELLOW}Dry run: nothing will be changed${C_RESET}"
    fi

    preflight
    # Both apt and /etc/shells need root; everything else runs as you.
    if $DO_APT || $SET_FISH_SHELL; then
        setup_sudo
    fi
    install_apt_packages
    install_mise
    link_configs
    install_mise_tools
    install_tmux_plugins
    sync_neovim
    install_herdr_plugins
    set_login_shell

    local elapsed=$(( $(date +%s) - start_time ))
    step "Done in $((elapsed / 60))m $((elapsed % 60))s"
    log "Log: $LOG_FILE"
    if [ -d "$BACKUP_DIR" ]; then
        log "Replaced configs were backed up to $BACKUP_DIR"
    fi
    printf '\nNext:\n'
    printf '  • Open a new shell so mise shims are on PATH.\n'
    if $SET_FISH_SHELL; then
        printf '  • Verify fish works in a second SSH session before closing this one.\n'
    else
        printf '  • Run ./install-pi --fish-shell to make fish your login shell.\n'
    fi
    printf "  • Sync shell history: atuin login -u <user>\n"
}

main "$@"
