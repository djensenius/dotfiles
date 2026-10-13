#!/usr/bin/env bash
# General Linux setup for supported workstation/server distros.
# Supports Arch and Debian/Ubuntu families; Raspberry Pi device provisioning
# remains in ../install-pi / pi/install.sh.
set -euo pipefail

LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$LINUX_DIR/.." && pwd)"

DO_PACKAGES=true
DO_LINKS=true
DO_MISE=true
DO_MISE_TOOLS=true
DO_AI_TOOLS=false
DRY_RUN=false
ASSUME_YES=false
FORCE=false
DISTRO_FAMILY=""
DISTRO_PRETTY=""
SUDO=""

DEBIAN_PACKAGES=(
    ca-certificates
    curl
    wget
    gpg
    git
    git-lfs
    fish
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
    btop
    tmux
)

ARCH_PACKAGES=(
    ca-certificates
    curl
    wget
    gnupg
    git
    git-lfs
    fish
    unzip
    zip
    xz
    tar
    rsync
    less
    glibc
    base-devel
    pkgconf
    openssl
    python
    python-pip
    btop
    tmux
)

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RESET=$'\033[0m'
else
    C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_RESET=''
fi

log()  { printf '%s\n' "$*"; }
step() { printf '\n%s==> %s%s\n' "$C_BOLD" "$*" "$C_RESET"; }
ok()   { log "${C_GREEN}✓${C_RESET} $*"; }
skip() { log "${C_DIM}·${C_RESET} $*"; }
warn() { log "${C_YELLOW}⚠${C_RESET} $*"; }
die()  { log "${C_RED}✗${C_RESET} $*"; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

show_help() {
    cat <<'EOF'
install-linux — provision a supported Linux machine with these dotfiles

Usage: ./install-linux [OPTIONS]

Supports distro families detected from /etc/os-release:
  • Debian/Ubuntu (apt-get)
  • Arch/Manjaro/EndeavourOS (pacman)

Runs, in order:
  1. baseline OS packages for the detected package manager
  2. common dotfile symlinks into ~/.config, keeping Herdr state dirs real
  3. mise installation, ~/.config/mise link, and global tool install
  4. optional AI/coding-agent tooling stack (with --ai-tools)

Options:
  --skip-packages    Do not install baseline OS packages
  --skip-links       Do not create common ~/.config symlinks (mise link uses --skip-mise)
  --skip-mise        Do not install mise or run mise install
  --skip-mise-tools  Install/link mise, but do not run mise install
  --ai-tools         Install ./ai-tools/install.sh after Linux setup (needs Git >= 2.45)
  --force            Replace existing config paths instead of leaving them alone
  --dry-run          Print what would run without changing anything
  --yes, -y          Do not prompt for confirmation
  --help, -h         Show this help

Unsupported distro families and Raspberry Pi OS fail before package-manager changes.
EOF
}

os_release_path() {
    printf '%s\n' "${INSTALL_LINUX_OS_RELEASE:-/etc/os-release}"
}

os_release_value() {
    local release="$1" key="$2" line value
    line="$(grep -E "^${key}=" "$release" | tail -n 1 || true)"
    [ -n "$line" ] || return 0
    value="${line#*=}"
    case "$value" in
        \"*\") value="${value#\"}"; value="${value%\"}" ;;
        \'*\') value="${value#\'}"; value="${value%\'}" ;;
    esac
    printf '%s\n' "$value"
}

detect_distro_family() {
    local release id id_like ids pretty_lc
    local os_id os_id_like os_pretty
    release="$(os_release_path)"
    [ -r "$release" ] || die "Cannot read $release; install-linux needs /etc/os-release"

    os_id="$(os_release_value "$release" ID)"
    os_id_like="$(os_release_value "$release" ID_LIKE)"
    os_pretty="$(os_release_value "$release" PRETTY_NAME)"
    id="$(printf '%s' "$os_id" | tr '[:upper:]' '[:lower:]')"
    id_like="$(printf '%s' "$os_id_like" | tr '[:upper:]' '[:lower:]')"
    ids=" $id $id_like "
    DISTRO_PRETTY="${os_pretty:-$os_id}"
    pretty_lc="$(printf '%s' "$DISTRO_PRETTY" | tr '[:upper:]' '[:lower:]')"

    case "$ids $pretty_lc" in
        *' raspbian '*|*' raspberry pi os '*)
            die "Raspberry Pi OS detected (${DISTRO_PRETTY:-unknown}); use ./install-pi for Raspberry Pi provisioning."
            ;;
    esac

    case "$ids" in
        *' arch '*|*' manjaro '*|*' endeavouros '*) DISTRO_FAMILY="arch" ;;
        *' debian '*|*' ubuntu '*) DISTRO_FAMILY="debian" ;;
        *)
            die "Unsupported Linux distro family '$os_id' (ID_LIKE='${os_id_like:-}'). install-linux supports Arch, Ubuntu, and Debian families."
            ;;
    esac
}

setup_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        die "Do not run install-linux as root or with sudo; run it as your normal user so dotfiles are installed in your home directory. The installer uses sudo only for package-manager commands."
    fi
    have sudo || die "sudo is not installed. Install sudo or install baseline packages separately and re-run with --skip-packages."
    SUDO="sudo"
    if sudo -n true 2>/dev/null; then
        ok "sudo available without a password prompt"
    else
        log "sudo needs your password for package installation."
        $DRY_RUN || sudo -v || die "Could not obtain sudo privileges"
    fi
}

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

as_user() {
    if $DRY_RUN; then
        log "${C_DIM}[dry-run] $*${C_RESET}"
        return 0
    fi
    "$@"
}

preflight() {
    step "Preflight"
    [ "$(uname -s)" = "Linux" ] || die "install-linux targets Linux. On macOS use ./install-mac."
    if [ "$(id -u)" -eq 0 ]; then
        die "Do not run install-linux as root or with sudo; run it as your normal user so dotfiles are installed in your home directory. The installer uses sudo only for package-manager commands."
    fi
    [ -d "$DOTFILES_DIR/fish" ] || die "$DOTFILES_DIR does not look like the dotfiles repo (no fish/ directory)."
    detect_distro_family
    ok "OS: $DISTRO_PRETTY ($DISTRO_FAMILY family)"
    ok "Dotfiles: $DOTFILES_DIR"
    if $DRY_RUN; then
        ok "Dry run: no changes will be made"
    fi

    if ! $ASSUME_YES && ! $DRY_RUN && [ -t 0 ]; then
        printf '\nProceed? [Y/n] '
        local reply
        read -r reply
        case "$reply" in
            [nN]*) die "Aborted." ;;
        esac
    fi
}

install_packages() {
    $DO_PACKAGES || { skip "Skipping baseline packages (--skip-packages)"; return; }
    step "Installing baseline packages"
    setup_sudo

    case "$DISTRO_FAMILY" in
        debian)
            have apt-get || die "apt-get not found for Debian/Ubuntu family install"
            as_root env DEBIAN_FRONTEND=noninteractive apt-get update
            as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${DEBIAN_PACKAGES[@]}"
            ok "Installed Debian/Ubuntu baseline packages"
            ;;
        arch)
            have pacman || die "pacman not found for Arch family install"
            as_root pacman -Syu --needed --noconfirm "${ARCH_PACKAGES[@]}"
            ok "Installed Arch baseline packages"
            ;;
    esac
}

backup_path_for() {
    local target="$1" backup suffix
    backup="$target.backup"
    suffix=1
    while [ -e "$backup" ] || [ -L "$backup" ]; do
        backup="$target.backup.$suffix"
        suffix=$((suffix + 1))
    done
    printf '%s\n' "$backup"
}

ensure_real_dir() {
    local dir="$1" backup
    if [ -d "$dir" ] && [ ! -L "$dir" ]; then
        skip "Real directory present: ${dir/#$HOME/\~}"
        return 0
    fi
    if [ -e "$dir" ] || [ -L "$dir" ]; then
        backup="$(backup_path_for "$dir")"
        as_user mv "$dir" "$backup"
        warn "Moved existing ${dir/#$HOME/\~} aside -> ${backup/#$HOME/\~}"
    fi
    as_user mkdir -p "$dir"
    ok "Created real directory: ${dir/#$HOME/\~}"
}

resolved_path() {
    local path="$1" dir base
    [ -e "$path" ] || [ -L "$path" ] || return 1
    dir="$(dirname "$path")"
    base="$(basename "$path")"
    (cd -P "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base")
}

mise_config_points_to_repo() {
    local active_config="$HOME/.config/mise/config.toml" repo_config="$DOTFILES_DIR/mise/config.toml"
    local active_resolved repo_resolved
    active_resolved="$(resolved_path "$active_config")" || return 1
    repo_resolved="$(resolved_path "$repo_config")" || return 1
    [ "$active_resolved" = "$repo_resolved" ]
}

add_mise_paths_to_path() {
    local bin_dir="$HOME/.local/bin" shims="$HOME/.local/share/mise/shims"
    case ":$PATH:" in
        *":$bin_dir:"*) ;;
        *) export PATH="$bin_dir:$PATH" ;;
    esac
    case ":$PATH:" in
        *":$shims:"*) ;;
        *) export PATH="$shims:$PATH" ;;
    esac
}

link_config() {
    local rel="$1" target="$2" src backup
    src="$DOTFILES_DIR/$rel"
    [ -e "$src" ] || { warn "Missing in repo, not linked: $rel"; return; }

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        skip "Already linked: ${target/#$HOME/\~}"
        return
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        if ! $FORCE; then
            warn "Leaving existing ${target/#$HOME/\~} in place (use --force to replace)"
            return
        fi
        backup="$(backup_path_for "$target")"
        as_user mv "$target" "$backup"
        warn "Moved existing ${target/#$HOME/\~} aside -> ${backup/#$HOME/\~}"
    fi

    as_user mkdir -p "$(dirname "$target")"
    as_user ln -sfn "$src" "$target"
    ok "Linked ${target/#$HOME/\~} -> $rel"
}

link_configs() {
    $DO_LINKS || { skip "Skipping symlinks (--skip-links)"; return; }
    step "Linking common dotfiles"

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

    # Herdr writes sockets, logs, session state and plugins under ~/.config/herdr,
    # so keep that directory real and link only the repo-owned config pieces.
    ensure_real_dir "$HOME/.config/herdr"
    link_config herdr/config.toml "$HOME/.config/herdr/config.toml"
    link_config herdr/scripts "$HOME/.config/herdr/scripts"
}

install_mise() {
    $DO_MISE || { skip "Skipping mise (--skip-mise)"; return; }
    step "Installing mise"

    if have mise; then
        ok "mise already installed ($(mise --version 2>/dev/null | head -1))"
    else
        have curl || die "curl is required to install mise; install packages first or provide mise on PATH"
        as_user bash -c 'curl -fsSL https://mise.run | sh'
        add_mise_paths_to_path
        if ! have mise && ! $DRY_RUN; then
            die "mise install failed"
        fi
        ok "mise installed to ~/.local/bin/mise"
    fi

    link_config mise "$HOME/.config/mise"
    if ! $DRY_RUN && ! mise_config_points_to_repo; then
        if $DO_MISE_TOOLS; then
            die "\$HOME/.config/mise/config.toml is not this repo's mise/config.toml. Re-run with --force to replace \$HOME/.config/mise, or use --skip-mise-tools to leave your existing mise config active."
        fi
        warn "\$HOME/.config/mise/config.toml is not this repo's mise/config.toml; repo tools are not active globally."
    fi

    $DO_MISE_TOOLS || { skip "Skipping mise tools (--skip-mise-tools)"; return; }
    if ! have mise && ! $DRY_RUN; then
        warn "mise not on PATH; skipping tool install"
        return 0
    fi
    log "Running mise install from ~/.config/mise/config.toml"
    as_user mise trust "$DOTFILES_DIR/mise/config.toml"
    as_user mise install -C "$HOME"
    add_mise_paths_to_path
    ok "mise tools installed"
}

install_ai_tools() {
    $DO_AI_TOOLS || return 0
    step "Installing AI/coding-agent tools"

    local installer="$DOTFILES_DIR/ai-tools/install.sh"
    [ -x "$installer" ] || die "AI tools installer not executable: $installer"
    as_user "$installer"
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --skip-packages)   DO_PACKAGES=false ;;
            --skip-links)      DO_LINKS=false ;;
            --skip-mise)       DO_MISE=false ;;
            --skip-mise-tools) DO_MISE_TOOLS=false ;;
            --ai-tools)        DO_AI_TOOLS=true ;;
            --force)           FORCE=true ;;
            --dry-run)         DRY_RUN=true ;;
            --yes|-y)          ASSUME_YES=true ;;
            --help|-h)         show_help; exit 0 ;;
            *) printf 'Unknown option: %s\nUse --help for usage.\n' "$1" >&2; exit 1 ;;
        esac
        shift
    done

    printf '%s🐧 install-linux — Linux dotfiles setup%s\n' "$C_BOLD" "$C_RESET"
    preflight
    install_packages
    link_configs
    install_mise
    install_ai_tools

    step "Done"
    printf '\nNext:\n'
    printf '  • Open a new shell and ensure ~/.local/bin plus ~/.local/share/mise/shims are on PATH.\n'
    printf "  • The linked fish config activates mise automatically; for bash/zsh, add mise activation to your shell rc (for example: eval \"\\\$(~/.local/bin/mise activate bash)\").\n"
    if $DO_AI_TOOLS; then
        printf '  • AI/coding-agent tooling was requested with ./install-linux --ai-tools.\n'
    else
        printf '  • Run ./install-linux --ai-tools to install the generalized AI/coding-agent tooling stack.\n'
    fi
}

main "$@"
