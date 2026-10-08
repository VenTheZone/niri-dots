#!/usr/bin/env bash
set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Options
SKIP_DEPS=false
SKIP_FONTS=false
DRY_RUN=false
ASSUME_YES=false
CHECK_ONLY=false
INSTALL_SDDM=false
ANIM=true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WARNINGS=0
CONFLICTS=0

# Niri 25.08+ has overview + spawn-sh-at-startup this rice uses
MIN_NIRI_VERSION="25.08"
MIN_KERNEL="6.1"
MIN_BASH_MAJOR=4

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --skip-deps    Skip dependency installation
  --skip-fonts   Skip font installation
  --dry-run      Show what would be done without making changes
  --yes, -y      Assume yes for prompts (needed for non-interactive)
  --check        Preflight only: OS, deps, conflicts — do not link
  --sddm         Also install the CRT TV SDDM login theme (needs sudo)
  --no-anim      Skip the jack-in animation
  -h, --help     Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-deps) SKIP_DEPS=true; shift ;;
        --skip-fonts) SKIP_FONTS=true; shift ;;
        --dry-run)
            DRY_RUN=true
            echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
            echo ""
            shift
            ;;
        --yes|-y) ASSUME_YES=true; shift ;;
        --check) CHECK_ONLY=true; shift ;;
        --sddm) INSTALL_SDDM=true; shift ;;
        --no-anim) ANIM=false; shift ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# --- jack-in animation: off for pipes, CI, TERM=dumb, non-UTF-8 locales or --no-anim ---
Y=$'\033[38;2;243;230;0m'
R=$'\033[38;2;255;0;60m'
C=$'\033[38;2;94;246;255m'
D=$'\033[38;2;110;110;120m'
BOLD=$'\033[1m'
Z=$'\033[0m'
LOGO=(
    '███╗   ██╗██╗██████╗ ██╗  ██████╗  ██████╗ ████████╗███████╗'
    '████╗  ██║██║██╔══██╗██║  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝'
    '██╔██╗ ██║██║██████╔╝██║  ██║  ██║██║   ██║   ██║   ███████╗'
    '██║╚██╗██║██║██╔══██╗██║  ██║  ██║██║   ██║   ██║   ╚════██║'
    '██║ ╚████║██║██║  ██║██║  ██████╔╝╚██████╔╝   ██║   ███████║'
    '╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝╚═╝  ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝'
)
GLITCH='▓▒░█▚▞#%&'
STAGE=0

anim_on() {
    [ "$ANIM" = true ] && [ -t 1 ] && [ -z "${CI:-}" ] && [ "${TERM:-dumb}" != dumb ] &&
        [ "$(locale charmap 2>/dev/null)" = UTF-8 ]
}

typeout() { # typeout COLOR TEXT [delay]
    local i
    if anim_on; then
        for ((i = 0; i < ${#2}; i++)); do printf '%s%s' "$1" "${2:i:1}"; sleep "${3:-0.012}"; done
        printf '%s\n' "$Z"
    else
        printf '%s%s%s\n' "$1" "$2" "$Z"
    fi
}

# one line of TEXT where unresolved characters are noise; frame F of N resolves it
glitch_line() {
    local text="$1" f="$2" n="$3" i ch out=""
    for ((i = 0; i < ${#text}; i++)); do
        ch="${text:i:1}"
        if [ "$ch" != " " ] && [ $((RANDOM % n)) -ge "$f" ]; then
            out+="${R}${GLITCH:RANDOM%${#GLITCH}:1}"
        else
            out+="${Y}${ch}"
        fi
    done
    printf '%s%s' "$out" "$Z"
}

intro() {
    local cols pad sp f w row
    cols="$(tput cols 2>/dev/null || echo 80)"
    pad=$(((cols - 60) / 2))
    [ "$pad" -lt 0 ] && pad=0
    sp="$(printf '%*s' "$pad" '')"
    echo
    if anim_on; then
        printf '\033[?25l'
        trap 'printf "\033[?25h"' EXIT
        # CRT power-on: a bright line stretches across the tube
        for w in 2 6 14 30 46 60; do
            printf '\r\033[K%*s%s%s%s' $((pad + (60 - w) / 2)) '' "$Y" "$(printf '━%.0s' $(seq "$w"))" "$Z"
            sleep 0.035
        done
        printf '\r\033[K'
        # logo decodes out of noise
        for f in 0 1 2 3 4 5 6; do
            for row in "${LOGO[@]}"; do printf '%s' "$sp"; glitch_line "$row" "$f" 6; echo; done
            sleep 0.06
            [ "$f" -lt 6 ] && printf '\033[%dA' "${#LOGO[@]}"
        done
        printf '\033[?25h'
    else
        for row in "${LOGO[@]}"; do printf '%s%s%s%s\n' "$sp" "$Y" "$row" "$Z"; done
    fi
    printf '%s' "$sp"; typeout "$C" "EDGERUNNERS // NIRI + QUICKSHELL // NIGHT CITY BUILD"
    printf '%s' "$sp"; typeout "$D" "> jacking in..." 0.03
}

stage() {
    local title="${1^^}" n i
    STAGE=$((STAGE + 1))
    n="$(printf '%02d' "$STAGE")"
    echo
    printf '%s▌ %s%s %s// %s' "$Y" "$BOLD" "$n" "$Z$D" "$C"
    if anim_on; then
        for ((i = 0; i < ${#title}; i++)); do printf '%s' "${title:i:1}"; sleep 0.006; done
        printf ' %s%s\033[16D%s' "$D" "$(printf '░%.0s' {1..16})" "$Y"
        for i in {1..16}; do printf '█'; sleep 0.008; done
        printf '%s\n' "$Z"
    else
        printf '%s %s%s%s\n' "$title" "$Y" "$(printf '█%.0s' {1..16})" "$Z"
    fi
}

outro() {
    local msg="SYSTEM ONLINE" f
    echo
    if anim_on; then
        for f in 0 1 2 3 4; do printf '\r  %s' "$BOLD"; glitch_line "$msg" "$f" 4; sleep 0.08; done
        echo
    else
        printf '  %s%s%s%s\n' "$BOLD" "$Y" "$msg" "$Z"
    fi
    typeout "$C" "  Wake up, choom. Log out and pick Niri at your login screen."
    echo
}

intro

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root!${NC}"
    echo "Run as your regular user: ./install.sh"
    exit 1
fi

warn() {
    echo -e "  ${YELLOW}⚠${NC} $*"
    WARNINGS=$((WARNINGS + 1))
}

fail() {
    echo -e "  ${RED}✗${NC} $*"
}

ok() {
    echo -e "  ${GREEN}✓${NC} $*"
}

info() {
    echo -e "  ${BLUE}→${NC} $*"
}

confirm() {
    local prompt="$1"
    if [ "$ASSUME_YES" = true ]; then
        return 0
    fi
    if [ ! -t 0 ]; then
        echo -e "${RED}Non-interactive stdin. Re-run with --yes to continue.${NC}"
        exit 1
    fi
    read -r -p "$prompt (y/n) " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

ver_ge() {
    local have="$1" need="$2"
    [ "$(printf '%s\n' "$have" "$need" | sort -V | tail -n1)" = "$have" ]
}

detect_package_manager() {
    if command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# arch / debian / fedora / suse, from ID then ID_LIKE in /etc/os-release
detect_distro_family() {
    local id
    # shellcheck disable=SC1091
    for id in $( . /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}" ); do
        case "$id" in
            arch|archarm|endeavouros|manjaro|cachyos|garuda|artix) echo arch; return ;;
            debian|ubuntu|linuxmint|pop|elementary|zorin) echo debian; return ;;
            fedora|nobara|rhel|centos|rocky|almalinux) echo fedora; return ;;
            opensuse*|suse|sles) echo suse; return ;;
        esac
    done
    echo unknown
}

DISTRO_FAMILY="$(detect_distro_family)"
case "$DISTRO_FAMILY" in
    arch) PKG_MANAGER=pacman ;;
    debian) PKG_MANAGER=apt ;;
    fedora) PKG_MANAGER=dnf ;;
    suse) PKG_MANAGER=zypper ;;
    *) PKG_MANAGER="$(detect_package_manager)" ;;
esac

# --- planned destinations (used by conflict check + linker) ---
declare -A LINK_FILES=(
    ["$SCRIPT_DIR/.config/niri/config.kdl"]="$HOME/.config/niri/config.kdl"
    ["$SCRIPT_DIR/.config/alacritty/alacritty.toml"]="$HOME/.config/alacritty/alacritty.toml"
        ["$SCRIPT_DIR/.config/kitty/kitty.conf"]="$HOME/.config/kitty/kitty.conf"
        ["$SCRIPT_DIR/.config/kitty/dark-theme.auto.conf"]="$HOME/.config/kitty/dark-theme.auto.conf"
        ["$SCRIPT_DIR/.config/kitty/tab_bar.py"]="$HOME/.config/kitty/tab_bar.py"
    ["$SCRIPT_DIR/.config/gtk-3.0/settings.ini"]="$HOME/.config/gtk-3.0/settings.ini"
    ["$SCRIPT_DIR/.config/gtk-4.0/settings.ini"]="$HOME/.config/gtk-4.0/settings.ini"
    ["$SCRIPT_DIR/.config/environment.d/80-cursor.conf"]="$HOME/.config/environment.d/80-cursor.conf"
    ["$SCRIPT_DIR/.local/share/icons/default/index.theme"]="$HOME/.local/share/icons/default/index.theme"
    ["$SCRIPT_DIR/.config/fuzzel/fuzzel.ini"]="$HOME/.config/fuzzel/fuzzel.ini"
    ["$SCRIPT_DIR/.config/waybar/config"]="$HOME/.config/waybar/config"
    ["$SCRIPT_DIR/.config/waybar/style.css"]="$HOME/.config/waybar/style.css"
    ["$SCRIPT_DIR/.config/waybar/launch.sh"]="$HOME/.config/waybar/launch.sh"
    ["$SCRIPT_DIR/.config/mako/config"]="$HOME/.config/mako/config"
    ["$SCRIPT_DIR/.config/gtk-3.0/gtk.css"]="$HOME/.config/gtk-3.0/gtk.css"
    ["$SCRIPT_DIR/.local/bin/screenshot-crop"]="$HOME/.local/bin/screenshot-crop"
    ["$SCRIPT_DIR/.local/bin/screenshot-window"]="$HOME/.local/bin/screenshot-window"
    ["$SCRIPT_DIR/.local/bin/powermenu"]="$HOME/.local/bin/powermenu"
    ["$SCRIPT_DIR/.local/bin/waybar-toggle"]="$HOME/.local/bin/waybar-toggle"
    ["$SCRIPT_DIR/.local/bin/waybar-debug"]="$HOME/.local/bin/waybar-debug"
    ["$SCRIPT_DIR/.local/bin/waybar-test"]="$HOME/.local/bin/waybar-test"
    ["$SCRIPT_DIR/.local/bin/volume-control"]="$HOME/.local/bin/volume-control"
    ["$SCRIPT_DIR/.local/bin/clipmenu.sh"]="$HOME/.local/bin/clipmenu.sh"
    ["$SCRIPT_DIR/.local/bin/wifi-menu"]="$HOME/.local/bin/wifi-menu"
    ["$SCRIPT_DIR/.local/bin/record-toggle"]="$HOME/.local/bin/record-toggle"
    ["$SCRIPT_DIR/.config/waybar/scripts/keyboard-backlight.sh"]="$HOME/.config/waybar/scripts/keyboard-backlight.sh"
    ["$SCRIPT_DIR/.config/waybar/scripts/network-bandwidth.sh"]="$HOME/.config/waybar/scripts/network-bandwidth.sh"
    ["$SCRIPT_DIR/.config/waybar/scripts/audio-control.sh"]="$HOME/.config/waybar/scripts/audio-control.sh"
    ["$SCRIPT_DIR/.config/waybar/scripts/audio-selector.sh"]="$HOME/.config/waybar/scripts/audio-selector.sh"
    ["$SCRIPT_DIR/.config/waybar/scripts/battery-status.sh"]="$HOME/.config/waybar/scripts/battery-status.sh"
    ["$SCRIPT_DIR/.config/waybar/scripts/mic-selector.sh"]="$HOME/.config/waybar/scripts/mic-selector.sh"
    ["$SCRIPT_DIR/.config/waybar/scripts/niri-workspaces.sh"]="$HOME/.config/waybar/scripts/niri-workspaces.sh"
    ["$SCRIPT_DIR/.config/waybar/scripts/volumecontrol.sh"]="$HOME/.config/waybar/scripts/volumecontrol.sh"
    ["$SCRIPT_DIR/.local/bin/audio-switch"]="$HOME/.local/bin/audio-switch"
    ["$SCRIPT_DIR/.config/environment.d/90-qt-theme.conf"]="$HOME/.config/environment.d/90-qt-theme.conf"
    ["$SCRIPT_DIR/.p10k.zsh"]="$HOME/.p10k.zsh"
    ["$SCRIPT_DIR/.config/swaylock/config"]="$HOME/.config/swaylock/config"
    ["$SCRIPT_DIR/.config/yazi/theme.toml"]="$HOME/.config/yazi/theme.toml"
    ["$SCRIPT_DIR/.config/fastfetch/config.jsonc"]="$HOME/.config/fastfetch/config.jsonc"
    ["$SCRIPT_DIR/.config/btop/themes/edgerunners.theme"]="$HOME/.config/btop/themes/edgerunners.theme"
    ["$SCRIPT_DIR/.config/vesktop/themes/edgerunners.theme.css"]="$HOME/.config/vesktop/themes/edgerunners.theme.css"
    ["$SCRIPT_DIR/.local/share/color-schemes/Edgerunners.colors"]="$HOME/.local/share/color-schemes/Edgerunners.colors"
    ["$SCRIPT_DIR/.zshrc"]="$HOME/.zshrc"
)

declare -A LINK_DIRS=(
    ["$SCRIPT_DIR/.config/niri/wallpaper"]="$HOME/.config/niri/wallpaper"
    ["$SCRIPT_DIR/.local/share/icons/Edgerunners"]="$HOME/.local/share/icons/Edgerunners"
    ["$SCRIPT_DIR/.config/quickshell"]="$HOME/.config/quickshell"
    ["$SCRIPT_DIR/.local/share/themes/Edge-Runner"]="$HOME/.local/share/themes/Edge-Runner"
)

check_platform() {
    stage "Platform scan"

    if [ "$(uname -s)" != "Linux" ]; then
        fail "This rice is Linux/Wayland only (found $(uname -s))"
        exit 1
    fi
    ok "Kernel: Linux $(uname -r) $(uname -m)"

    local bash_major="${BASH_VERSINFO[0]}"
    if [ "$bash_major" -lt "$MIN_BASH_MAJOR" ]; then
        fail "Bash $MIN_BASH_MAJOR+ required (found $BASH_VERSION)"
        exit 1
    fi
    ok "Bash $BASH_VERSION"

    local kver
    kver="$(uname -r | cut -d- -f1)"
    if ver_ge "$kver" "$MIN_KERNEL"; then
        ok "Kernel $kver >= $MIN_KERNEL"
    else
        warn "Kernel $kver is older than $MIN_KERNEL — Niri/Wayland may be rough"
    fi

    if [ ! -r /etc/os-release ]; then
        fail "Cannot read /etc/os-release"
        exit 1
    fi
    # shellcheck disable=SC1091
    . /etc/os-release
    local distro_id="${ID:-unknown}"
    local pretty="${PRETTY_NAME:-$distro_id}"
    local version="${VERSION_ID:-${BUILD_ID:-unknown}}"
    ok "Distro: $pretty ($distro_id $version)"
    info "Family: $DISTRO_FAMILY, package manager: $PKG_MANAGER"

    case "$DISTRO_FAMILY" in
        arch)
            ok "Primary supported family (Arch): everything installs from repos/AUR"
            ;;
        debian|fedora|suse)
            warn "$DISTRO_FAMILY family is best-effort: packages missing from your repos are listed with install hints"
            ;;
        *)
            warn "Untested distro '$distro_id': packages are checked but not auto-installed"
            ;;
    esac

    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64|aarch64) ok "CPU arch $arch" ;;
        *) warn "Untested CPU arch $arch" ;;
    esac

    if command -v systemctl &>/dev/null && [ "$(ps -p 1 -o comm= 2>/dev/null)" = "systemd" ]; then
        ok "systemd is pid 1"
    else
        warn "systemd not pid 1 — bluetooth enable and session files may not apply"
    fi

    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        ok "Current session is Wayland (${XDG_CURRENT_DESKTOP:-unknown})"
    elif [ -n "${WAYLAND_DISPLAY:-}" ]; then
        ok "WAYLAND_DISPLAY is set"
    else
        warn "Not in a Wayland session now — fine for install, need a Wayland login to run Niri"
    fi

    if [ -d /usr/share/wayland-sessions ]; then
        ok "wayland-sessions directory exists"
    else
        warn "No /usr/share/wayland-sessions — display manager may not list Niri"
    fi

    echo ""
}

verify_structure() {
    # everything the linker uses, plus assets read in place
    local required_files=("${!LINK_FILES[@]}")
    local src
    for src in "${!LINK_DIRS[@]}"; do required_files+=("$src/."); done
    required_files+=(
        "$SCRIPT_DIR/.config/quickshell/shell.qml"
        "$SCRIPT_DIR/.config/niri/wallpaper/posters/posters.json"
        "$SCRIPT_DIR/.config/niri/wallpaper/tv/."
        "$SCRIPT_DIR/.config/zen/userChrome.css"
        "$SCRIPT_DIR/sddm/edgerunners-crt/Main.qml"
    )

    local missing=()

    stage "Verifying shards"
    for file in "${required_files[@]}"; do
        file="${file#"$SCRIPT_DIR"/}"
        if [ ! -e "$SCRIPT_DIR/$file" ]; then
            missing+=("$file")
            fail "$file"
        else
            ok "$file"
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Error: Missing required files. Run from the niri-dots repo root.${NC}"
        exit 1
    fi

    echo ""
    echo -e "${GREEN}✓ All required files found${NC}"
    echo ""
}

check_niri_version() {
    if ! command -v niri &>/dev/null; then
        return 0
    fi
    local raw ver
    raw="$(niri --version 2>/dev/null | head -n1 || true)"
    ver="$(printf '%s\n' "$raw" | grep -oE '[0-9]+\.[0-9]+' | head -n1 || true)"
    if [ -z "$ver" ]; then
        warn "Could not parse niri version ($raw)"
        return 0
    fi
    if ver_ge "$ver" "$MIN_NIRI_VERSION"; then
        ok "niri $ver >= $MIN_NIRI_VERSION"
    else
        warn "niri $ver < $MIN_NIRI_VERSION — overview/backdrop rules in this rice may fail"
    fi
}

# package:check (Arch names). check is a binary on PATH, an absolute path,
# or @ to ask the package manager (libraries live in different paths per distro).
REQUIRED_DEPS=(
    "niri:niri"
    "waybar:waybar"
    "alacritty:alacritty"
    "fuzzel:fuzzel"
    "grim:grim"
    "slurp:slurp"
    "swaylock:swaylock"
    "swaybg:swaybg"
    "awww:awww"
    "quickshell:qs"
    "wf-recorder:wf-recorder"
    "wl-clipboard:wl-copy"
    "libnotify:notify-send"
    "mako:mako"
    "networkmanager:nmcli"
    "bluez:bluetoothctl"
    "blueman:blueman-manager"
    "playerctl:playerctl"
    "brightnessctl:brightnessctl"
    "upower:upower"
    "cliphist:cliphist"
    "wireplumber:wpctl"
    "libpulse:pactl"
    "jq:jq"
    "bc:bc"
    "curl:curl"
    "unzip:unzip"
    "git:git"
    "zsh:zsh"
    "fzf:fzf"
    "qt6-multimedia:@"
    "qt6-multimedia-ffmpeg:@"
)

OPTIONAL_DEPS=(
    "kitty:kitty"
    "dolphin:dolphin"
    "yazi:yazi"
    "btop:btop"
    "fastfetch:fastfetch"
    "mpv:mpv"
    "papirus-icon-theme:/usr/share/icons/Papirus-Dark"
    "plasma-integration:@"
    "plasma-workspace:plasma-apply-colorscheme"
    "asusctl:asusctl"
    "sddm:sddm-greeter-qt6"
)

# AUR only: installed with paru/yay when present
AUR_DEPS=(
    "zen-browser-bin:zen-browser"
    "vesktop:vesktop"
    "beautyline:/usr/share/icons/BeautyLine"
)

# Arch name -> "debian fedora suse" where they differ; - means that family doesn't package it
declare -A PKG_NAMES=(
    [quickshell]="- - -"
    [awww]="- - -"
    [libnotify]="libnotify-bin libnotify libnotify-tools"
    [mako]="mako-notifier mako mako"
    [networkmanager]="network-manager NetworkManager NetworkManager"
    [libpulse]="pulseaudio-utils pulseaudio-utils pulseaudio-utils"
    [qt6-multimedia]="qml6-module-qtmultimedia qt6-qtmultimedia qt6-multimedia"
    [qt6-multimedia-ffmpeg]="libqt6multimedia6 qt6-qtmultimedia qt6-multimedia"
    [plasma-integration]="plasma-integration plasma-integration plasma6-integration"
    [plasma-workspace]="plasma-workspace plasma-workspace plasma6-workspace"
    [yazi]="- - yazi"
    [asusctl]="- - asusctl"
)

# where to get what a distro doesn't ship
declare -A PKG_HINTS=(
    [niri]="https://github.com/YaLTeR/niri/wiki/Getting-Started"
    [quickshell]="https://quickshell.org/docs/guide/install-setup (Fedora: COPR errornointernet/quickshell)"
    [awww]="https://codeberg.org/LGFae/awww (cargo build --release)"
    [cliphist]="go install go.senan.xyz/cliphist@latest"
    [yazi]="cargo install --locked yazi-fm yazi-cli"
    [asusctl]="https://asus-linux.org"
    [zen-browser-bin]="flatpak install flathub app.zen_browser.zen"
    [vesktop]="flatpak install flathub dev.vencord.Vesktop"
)

map_pkg() {
    local pkg="$1" names deb fed suse
    names="${PKG_NAMES[$pkg]:-}"
    if [ -z "$names" ] || [ "$DISTRO_FAMILY" = arch ]; then
        echo "$pkg"
        return
    fi
    read -r deb fed suse <<<"$names"
    case "$DISTRO_FAMILY" in
        debian) echo "$deb" ;;
        fedora) echo "$fed" ;;
        suse) echo "$suse" ;;
        *) echo "$pkg" ;;
    esac
}

pkg_installed() {
    case "$PKG_MANAGER" in
        pacman) pacman -Q "$1" &>/dev/null ;;
        apt) dpkg -s "$1" 2>/dev/null | grep '^Status:.* installed' >/dev/null ;;
        dnf|yum|zypper) rpm -q "$1" &>/dev/null ;;
        *) return 1 ;;
    esac
}

pkg_available() {
    case "$PKG_MANAGER" in
        pacman) pacman -Si "$1" &>/dev/null ;;
        apt) [ -n "$(apt-cache policy "$1" 2>/dev/null | grep -v '(none)' | grep 'Candidate:')" ] ;;
        dnf|yum) "$PKG_MANAGER" -q info "$1" &>/dev/null ;;
        zypper) zypper -q info "$1" 2>/dev/null | grep '^Name' >/dev/null ;;
        *) return 1 ;;
    esac
}

# check is a command, a path (also accepted under ~/.local for /usr/share paths), or @ for a package query
have_dep() {
    local check="$1" pkg="$2"
    if [ "$check" = "@" ]; then
        [ "$pkg" != "-" ] && pkg_installed "$pkg"
        return
    fi
    command -v "$check" &>/dev/null || [ -e "$check" ] || [ -e "$HOME/.local${check#/usr}" ]
}

install_packages() {
    local packages=("$@")
    if [ ${#packages[@]} -eq 0 ]; then
        return 0
    fi
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would install: ${packages[*]}"
        return 0
    fi

    case "$PKG_MANAGER" in
        pacman) sudo pacman -S --needed --noconfirm "${packages[@]}" ;;
        apt) sudo apt update && sudo apt install -y "${packages[@]}" ;;
        dnf) sudo dnf install -y "${packages[@]}" ;;
        yum) sudo yum install -y "${packages[@]}" ;;
        zypper) sudo zypper install -y "${packages[@]}" ;;
        *)
            echo "Unsupported package manager. Install manually: ${packages[*]}"
            return 1
            ;;
    esac
}

check_dependencies() {
    stage "Dependency check"

    local missing=()
    local optional_missing=()
    local aur_missing=()
    local unavailable=()
    local item pkg bin mapped kind

    # sorts each dep into installed / installable from your repos / not packaged here
    sort_dep() {
        local arch_pkg="$1" check="$2" label="$3"
        mapped="$(map_pkg "$arch_pkg")"
        if have_dep "$check" "$mapped"; then
            ok "$arch_pkg${label}"
        elif [ "$mapped" != "-" ] && pkg_available "$mapped"; then
            if [ -n "$label" ]; then warn "$arch_pkg${label} missing"; else fail "$arch_pkg missing (package $mapped)"; fi
            return 1
        else
            if [ -n "$label" ]; then warn "$arch_pkg${label} not in $DISTRO_FAMILY repos"; else fail "$arch_pkg not in $DISTRO_FAMILY repos"; fi
            unavailable+=("$arch_pkg")
        fi
    }

    for item in "${REQUIRED_DEPS[@]}"; do
        sort_dep "${item%%:*}" "${item#*:}" "" || {
            [[ " ${missing[*]-} " =~ " ${mapped} " ]] || missing+=("$mapped")
        }
    done

    for item in "${OPTIONAL_DEPS[@]}"; do
        sort_dep "${item%%:*}" "${item#*:}" " (optional)" || optional_missing+=("$mapped")
    done

    for item in "${AUR_DEPS[@]}"; do
        pkg="${item%%:*}"
        bin="${item#*:}"
        if have_dep "$bin" "$pkg"; then
            ok "$pkg (optional)"
        elif [ "$DISTRO_FAMILY" = arch ]; then
            warn "$pkg (AUR, optional) missing"
            aur_missing+=("$pkg")
        else
            warn "$pkg (optional) missing"
            unavailable+=("$pkg")
        fi
    done

    check_niri_version
    echo ""

    if [ ${#unavailable[@]} -gt 0 ]; then
        echo -e "${YELLOW}Not packaged for $DISTRO_FAMILY, install by hand:${NC}"
        for pkg in "${unavailable[@]}"; do
            info "$pkg: ${PKG_HINTS[$pkg]:-check your distro or build from source}"
        done
        echo ""
    fi

    if [ "$CHECK_ONLY" = true ]; then
        [ ${#missing[@]} -gt 0 ] && echo -e "${YELLOW}Missing required: ${missing[*]}${NC}"
        [ ${#optional_missing[@]} -gt 0 ] && echo -e "${YELLOW}Missing optional: ${optional_missing[*]}${NC}"
        [ ${#aur_missing[@]} -gt 0 ] && echo -e "${YELLOW}Missing AUR: ${aur_missing[*]}${NC}"
        echo ""
        return 0
    fi

    if [ "$PKG_MANAGER" = unknown ]; then
        [ ${#missing[@]} -gt 0 ] && info "Install by hand, then re-run: ${missing[*]} ${optional_missing[*]}"
        echo ""
        return 0
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Missing required packages: ${missing[*]}${NC}"
        if confirm "Install missing required packages now?"; then
            install_packages "${missing[@]}" || warn "Some packages failed to install"
            if [[ " ${missing[*]} " =~ " bluez " ]]; then
                echo -e "${YELLOW}Enabling bluetooth service...${NC}"
                if [ "$DRY_RUN" = true ]; then
                    echo -e "${BLUE}[DRY RUN]${NC} Would enable bluetooth"
                else
                    sudo systemctl enable --now bluetooth || echo -e "${RED}Failed to enable bluetooth${NC}"
                fi
            fi
        else
            echo "Skipping package installation."
        fi
    else
        echo -e "${GREEN}✓ Required packages present${NC}"
    fi

    if [ ${#optional_missing[@]} -gt 0 ]; then
        echo -e "${YELLOW}Optional (themed apps, Qt colour scheme, login screen): ${optional_missing[*]}${NC}"
        if confirm "Install optional packages too?"; then
            install_packages "${optional_missing[@]}" || warn "Some optional packages failed to install"
        fi
    fi

    if [ ${#aur_missing[@]} -gt 0 ]; then
        local helper=""
        command -v paru &>/dev/null && helper=paru
        [ -z "$helper" ] && command -v yay &>/dev/null && helper=yay
        if [ -z "$helper" ]; then
            info "AUR packages (install with paru/yay): ${aur_missing[*]}"
        elif confirm "Install AUR packages with $helper (${aur_missing[*]})?"; then
            if [ "$DRY_RUN" = true ]; then
                echo -e "${BLUE}[DRY RUN]${NC} Would run: $helper -S --needed ${aur_missing[*]}"
            else
                "$helper" -S --needed --noconfirm "${aur_missing[@]}" || warn "Some AUR packages failed"
            fi
        fi
    fi
    echo ""
}

check_conflicts() {
    stage "Conflict sweep"
    CONFLICTS=0
    local src dst target

    for src in "${!LINK_FILES[@]}"; do
        dst="${LINK_FILES[$src]}"
        if [ -L "$dst" ]; then
            target="$(readlink -f "$dst" || true)"
            if [[ "$target" == "$SCRIPT_DIR"* ]]; then
                ok "$(basename "$dst") already linked here"
            else
                fail "$dst → $target (foreign symlink, would be overwritten)"
                CONFLICTS=$((CONFLICTS + 1))
            fi
        elif [ -e "$dst" ]; then
            if [ "$dst" = "$HOME/.zshrc" ]; then
                fail "$dst exists — installer replaces your whole zshrc (backup first)"
                CONFLICTS=$((CONFLICTS + 1))
            else
                warn "$dst exists and is not a symlink — will be backed up"
            fi
        fi
    done

    for src in "${!LINK_DIRS[@]}"; do
        dst="${LINK_DIRS[$src]}"
        if [ -L "$dst" ]; then
            target="$(readlink -f "$dst" || true)"
            if [[ "$target" == "$SCRIPT_DIR"* ]]; then
                ok "$(basename "$dst")/ already linked here"
            else
                fail "$dst → $target (foreign dir symlink)"
                CONFLICTS=$((CONFLICTS + 1))
            fi
        elif [ -e "$dst" ]; then
            warn "$dst exists — directory will be backed up"
        fi
    done

    if [ -f "$HOME/.config/waybar/config.jsonc" ] && [ ! -L "$HOME/.config/waybar/config.jsonc" ]; then
        fail "waybar config.jsonc exists alongside config — Waybar can load the wrong file"
        CONFLICTS=$((CONFLICTS + 1))
    fi

    if [ -d "$HOME/.config/hypr" ] && [ "${XDG_CURRENT_DESKTOP:-}" = "Hyprland" ]; then
        warn "Hyprland is the current desktop — this rice is for Niri"
    fi

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        warn "~/.local/bin is not on PATH — screenshot/powermenu binds will miss"
    else
        ok "~/.local/bin is on PATH"
    fi

    if grep -q '/home/jt/' "$SCRIPT_DIR/.config/niri/config.kdl" 2>/dev/null; then
        if [ "$HOME" != "/home/jt" ]; then
            fail "niri config hardcodes /home/jt but HOME=$HOME — wallpaper/scripts will miss"
            CONFLICTS=$((CONFLICTS + 1))
        else
            info "niri config still has hardcoded /home/jt paths (ok on this machine)"
        fi
    fi

    echo ""
    if [ "$CONFLICTS" -gt 0 ]; then
        echo -e "${RED}$CONFLICTS conflict(s) need a decision before linking.${NC}"
        echo ""
        if [ "$CHECK_ONLY" = true ]; then
            return 0
        fi
        if ! confirm "Continue anyway?"; then
            echo "Aborted."
            exit 1
        fi
    else
        echo -e "${GREEN}✓ No blocking conflicts${NC}"
        echo ""
    fi
}

install_fonts() {
    stage "Fonts"

    # family|arch package|zip url (used when there is no package or no pacman)
    local nf=https://github.com/ryanoasis/nerd-fonts/releases/latest/download
    local fonts=(
        "JetBrainsMono Nerd Font|ttf-jetbrains-mono-nerd|$nf/JetBrainsMono.zip"
        "Symbols Nerd Font|ttf-nerd-fonts-symbols|$nf/NerdFontsSymbolsOnly.zip"
        "Maple Mono||https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-TTF.zip"
    )
    local item family pkg url pkgs=() zips=()
    for item in "${fonts[@]}"; do
        IFS='|' read -r family pkg url <<<"$item"
        # no grep -q: with pipefail an early exit would SIGPIPE fc-list and read as "missing"
        if fc-list : family 2>/dev/null | grep -iF "$family" >/dev/null; then
            ok "$family"
        elif [ -n "$pkg" ] && [ "$PKG_MANAGER" = pacman ]; then
            pkgs+=("$pkg")
        else
            zips+=("$family|$url")
        fi
    done

    if [ "$DRY_RUN" = true ]; then
        [ ${#pkgs[@]} -gt 0 ] && echo -e "${BLUE}[DRY RUN]${NC} Would install: ${pkgs[*]}"
        for item in "${zips[@]}"; do echo -e "${BLUE}[DRY RUN]${NC} Would download ${item%%|*}"; done
        return 0
    fi

    if [ ${#pkgs[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${pkgs[@]}" || warn "Font package install failed"
    fi
    local tmp dir
    for item in "${zips[@]}"; do
        family="${item%%|*}"
        url="${item#*|}"
        dir="$HOME/.local/share/fonts/${family// /}"
        tmp="$(mktemp -d)"
        if curl -fsSL -o "$tmp/font.zip" "$url" && mkdir -p "$dir" && unzip -oq "$tmp/font.zip" -d "$dir"; then
            ok "$family → $dir"
        else
            warn "$family download failed, install it by hand"
        fi
        rm -rf "$tmp"
    done
    fc-cache -f >/dev/null 2>&1 || true
}

create_directories() {
    stage "Directories"

    local dirs=(
        "$HOME/.config/niri"
        "$HOME/.config/alacritty"
        "$HOME/.config/kitty"
        "$HOME/.config/gtk-3.0"
        "$HOME/.config/gtk-4.0"
        "$HOME/.config/environment.d"
        "$HOME/.local/share/icons"
        "$HOME/.local/share/icons/default"
        "$HOME/.config/fuzzel"
        "$HOME/.config/waybar"
        "$HOME/.config/waybar/scripts"
        "$HOME/.local/bin"
        "$HOME/Pictures/Screenshots"
    )

    if [ "$DRY_RUN" = true ]; then
        local dir
        for dir in "${dirs[@]}"; do
            echo -e "${BLUE}[DRY RUN]${NC} Would create: $dir"
        done
        echo -e "${BLUE}[DRY RUN]${NC} ✓ Directories would be created"
        return 0
    fi

    local dir
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done

    echo "  ✓ Directories created"
}

link_dotfiles() {
    stage "Linking dotfiles"

    local errors=0
    local src dst backup

    for src in "${!LINK_FILES[@]}"; do
        dst="${LINK_FILES[$src]}"

        if [ ! -f "$src" ]; then
            fail "Source not found: $src"
            errors=$((errors + 1))
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN]${NC} Would link: $src → $dst"
            continue
        fi

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            backup="$dst.backup.$(date +%Y%m%d_%H%M%S)"
            info "Backing up: $dst → $backup"
            mv "$dst" "$backup"
        fi

        mkdir -p "$(dirname "$dst")"
        ln -sfn "$src" "$dst"
        ok "Linked: $(basename "$dst")"
    done

    local scripts=(
        "$SCRIPT_DIR"/.local/bin/*
        "$SCRIPT_DIR"/.config/waybar/scripts/*.sh
        "$SCRIPT_DIR/.config/waybar/launch.sh"
    )
    if [ "$DRY_RUN" = false ]; then
        local f
        for f in "${scripts[@]}"; do
            if [ -f "$f" ]; then
                chmod +x "$f"
            fi
        done
    fi

    for src in "${!LINK_DIRS[@]}"; do
        dst="${LINK_DIRS[$src]}"

        if [ ! -d "$src" ]; then
            fail "Source directory not found: $src"
            errors=$((errors + 1))
            continue
        fi

        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN]${NC} Would link directory: $src → $dst"
            continue
        fi

        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            backup="$dst.backup.$(date +%Y%m%d_%H%M%S)"
            info "Backing up: $dst → $backup"
            mv "$dst" "$backup"
        fi

        mkdir -p "$(dirname "$dst")"
        ln -sfn "$src" "$dst"
        ok "Linked directory: $(basename "$dst")"
    done

    if [ "$errors" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}  ✓ All dotfiles linked successfully${NC}"
    else
        echo ""
        echo -e "${YELLOW}  ⚠ Completed with $errors errors${NC}"
    fi
}

setup_wallpaper() {
    stage "Wallpaper"

    local config="$HOME/.config/niri/config.kdl"

    if grep -q "exec qs" "$config" 2>/dev/null; then
        ok "Poster wallpaper starts with Quickshell (swaybg fallback)"
        info "Change it with Mod+Alt+W; add posters in ~/.config/niri/wallpaper/posters/posters.json"
    else
        warn "niri config does not start Quickshell, so no poster wallpaper"
    fi
}

setup_session_file() {
    stage "Login session"

    local session_file="/usr/share/wayland-sessions/niri.desktop"

    if [ -f "$session_file" ]; then
        ok "Niri session file already exists"
        return 0
    fi

    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would create: $session_file"
        return 0
    fi

    info "Creating niri.desktop session file..."

    if sudo tee "$session_file" >/dev/null <<'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri
Type=Application
EOF
    then
        ok "Session file created at $session_file"
        info "Niri will appear in the display manager on next login"
    else
        fail "Failed to create session file"
        warn "Create $session_file as root with Name=Niri and Exec=niri"
    fi
}

# .zshrc expects oh-my-zsh with powerlevel10k and these custom plugins
setup_zsh() {
    stage "Shell"
    local omz="$HOME/.oh-my-zsh" custom="$HOME/.oh-my-zsh/custom"
    local repos=(
        "$omz|https://github.com/ohmyzsh/ohmyzsh.git"
        "$custom/themes/powerlevel10k|https://github.com/romkatv/powerlevel10k.git"
        "$custom/plugins/zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git"
        "$custom/plugins/zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "$custom/plugins/zsh-completions|https://github.com/zsh-users/zsh-completions.git"
        "$custom/plugins/zsh-history-substring-search|https://github.com/zsh-users/zsh-history-substring-search.git"
        "$custom/plugins/forgit|https://github.com/wfxr/forgit.git"
    )
    local item dir url missing=()
    for item in "${repos[@]}"; do
        dir="${item%%|*}"
        if [ -d "$dir" ]; then
            ok "$(basename "$dir")"
        else
            missing+=("$item")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            for item in "${missing[@]}"; do echo -e "${BLUE}[DRY RUN]${NC} Would clone ${item#*|}"; done
        elif confirm "Clone ${#missing[@]} missing zsh pieces (oh-my-zsh/p10k/plugins)?"; then
            for item in "${missing[@]}"; do
                dir="${item%%|*}"
                url="${item#*|}"
                git clone --depth 1 "$url" "$dir" >/dev/null 2>&1 && ok "Cloned $(basename "$dir")" || warn "Clone failed: $url"
            done
        fi
    fi

    # ZSH_THEME="powerlevel10k" looks for themes/powerlevel10k.zsh-theme
    if [ "$DRY_RUN" = false ] && [ -d "$custom/themes/powerlevel10k" ] && [ ! -e "$custom/themes/powerlevel10k.zsh-theme" ]; then
        ln -s "$custom/themes/powerlevel10k/powerlevel10k.zsh-theme" "$custom/themes/powerlevel10k.zsh-theme"
    fi

    if [ "$(basename "${SHELL:-}")" != zsh ]; then
        info "Login shell is ${SHELL:-unset}; .zshrc applies in zsh (default it with: chsh -s $(command -v zsh || echo /usr/bin/zsh))"
    fi
}

setup_theming() {
    stage "App theming"
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would apply KDE colour scheme, btop theme, Zen userChrome"
        return 0
    fi

    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme Edgerunners >/dev/null && ok "KDE/Qt colour scheme: Edgerunners"
    fi

    local btop_conf="$HOME/.config/btop/btop.conf"
    if [ -f "$btop_conf" ]; then
        sed -i 's/^color_theme = .*/color_theme = "edgerunners"/' "$btop_conf"
    else
        mkdir -p "$(dirname "$btop_conf")"
        echo 'color_theme = "edgerunners"' > "$btop_conf"
    fi
    ok "btop theme: edgerunners"

    # Zen keeps its default profile in installs.ini
    local zen_profile
    zen_profile="$(grep -m1 '^Default=' "$HOME/.zen/installs.ini" 2>/dev/null | cut -d= -f2-)" || true
    if [ -n "$zen_profile" ] && [ -d "$HOME/.zen/$zen_profile" ]; then
        mkdir -p "$HOME/.zen/$zen_profile/chrome"
        ln -sfn "$SCRIPT_DIR/.config/zen/userChrome.css" "$HOME/.zen/$zen_profile/chrome/userChrome.css"
        ln -sfn "$SCRIPT_DIR/.config/zen/user.js" "$HOME/.zen/$zen_profile/user.js"
        ok "Zen userChrome linked into $zen_profile (restart Zen)"
    fi

    info "Vesktop: enable 'edgerunners.theme.css' under Settings > Themes"
}

# Opt-in (--sddm): needs root, copies the CRT login theme plus its fonts/shader/clips
install_sddm_theme() {
    stage "Login screen (sddm)"
    local dst=/usr/share/sddm/themes/edgerunners-crt
    if ! command -v sddm-greeter-qt6 &>/dev/null; then
        warn "sddm (Qt6 greeter) not installed, skipping login theme"
        return 0
    fi
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would install $dst and set it in /etc/sddm.conf"
        return 0
    fi
    sudo rm -rf "$dst"
    sudo mkdir -p "$dst/fonts" "$dst/tv"
    sudo cp "$SCRIPT_DIR"/sddm/edgerunners-crt/* "$dst/"
    sudo cp "$SCRIPT_DIR/.config/quickshell/fonts/Silkscreen-Bold.ttf" "$dst/fonts/"
    sudo cp "$SCRIPT_DIR/.config/quickshell/shaders/crt.frag.qsb" "$dst/"
    sudo cp "$SCRIPT_DIR"/.config/niri/wallpaper/tv/* "$dst/tv/"
    sudo cp "$SCRIPT_DIR/.config/niri/wallpaper/posters/david.jpg" "$dst/room.jpg"

    # /etc/sddm.conf overrides sddm.conf.d, so set the theme there
    if [ -f /etc/sddm.conf ] && grep -q '^\[Theme\]' /etc/sddm.conf; then
        sudo cp /etc/sddm.conf "/etc/sddm.conf.backup.$(date +%Y%m%d_%H%M%S)"
        if grep -q '^Current=' /etc/sddm.conf; then
            sudo sed -i 's/^Current=.*/Current=edgerunners-crt/' /etc/sddm.conf
        else
            sudo sed -i '/^\[Theme\]/a Current=edgerunners-crt' /etc/sddm.conf
        fi
    else
        printf '[Theme]\nCurrent=edgerunners-crt\n' | sudo tee -a /etc/sddm.conf >/dev/null
    fi
    ok "SDDM theme set (preview: sddm-greeter-qt6 --test-mode --theme $dst)"
}

print_summary() {
    stage "Summary"
    echo "  Warnings: $WARNINGS   Conflicts seen: $CONFLICTS"
    echo ""
    local bind
    for bind in \
        "Mod+Return|Kitty (Lucy)" \
        "Mod+Backspace|Alacritty (David)" \
        "Mod+D|Launcher" \
        "Mod+Alt+W|Wallpaper dial (or right-click the desktop)" \
        "Mod+Alt+R|Reveal poster colours (or left-click the desktop)" \
        "Mod+Alt+M|Music player" \
        "Mod+Shift+L|CRT lock screen" \
        "Mod+Shift+M|Power menu" \
        "Mod+Shift+/|Every keybind"; do
        printf '  %s%-14s%s %s\n' "$Y" "${bind%%|*}" "$Z" "${bind#*|}"
    done
    outro
}

main() {
    check_platform
    verify_structure
    check_conflicts

    if [ "$SKIP_DEPS" = false ]; then
        check_dependencies
    else
        echo -e "${YELLOW}Skipping dependency installation (--skip-deps)${NC}"
        echo ""
    fi

    if [ "$CHECK_ONLY" = true ]; then
        echo "=== Preflight complete ==="
        echo "Warnings: $WARNINGS   Conflicts: $CONFLICTS"
        if [ "$CONFLICTS" -gt 0 ]; then
            exit 2
        fi
        exit 0
    fi

    if [ "$SKIP_FONTS" = false ]; then
        install_fonts
    else
        echo -e "${YELLOW}Skipping font installation (--skip-fonts)${NC}"
        echo ""
    fi

    create_directories
    link_dotfiles
    setup_zsh
    setup_theming
    setup_wallpaper
    setup_session_file
    if [ "$INSTALL_SDDM" = true ]; then
        install_sddm_theme
    fi
    print_summary
}

main "$@"
