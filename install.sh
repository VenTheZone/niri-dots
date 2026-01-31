#!/bin/bash
set -e

echo "=== Niri Dots Installation ==="
echo ""

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

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --skip-fonts)
            SKIP_FONTS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
            echo ""
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-deps    Skip dependency installation"
            echo "  --skip-fonts   Skip font installation"
            echo "  --dry-run      Show what would be done without making changes"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root!${NC}"
    echo "Run as your regular user: ./install.sh"
    exit 1
fi

# Detect package manager
detect_package_manager() {
    if command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v apt &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_package_manager)

echo "Detected package manager: $PKG_MANAGER"
echo ""

# Verify script directory structure
verify_structure() {
    local required_files=(
        ".config/niri/config.kdl"
        ".config/alacritty/alacritty.toml"
        ".config/fuzzel/fuzzel.ini"
        ".config/waybar/config"
        ".config/waybar/style.css"
        ".local/bin/screenshot-crop"
        ".local/bin/powermenu"
        ".local/bin/waybar-toggle"
        ".local/bin/waybar-debug"
        ".local/bin/waybar-test"
        ".local/bin/volume-control"
        ".zshrc"
    )
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local missing=()
    
    echo -e "${YELLOW}Verifying dotfiles structure...${NC}"
    for file in "${required_files[@]}"; do
        if [ ! -f "$script_dir/$file" ]; then
            missing+=("$file")
        else
            echo -e "  ${GREEN}✓${NC} $file"
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}Error: Missing required files:${NC}"
        for file in "${missing[@]}"; do
            echo -e "  ${RED}✗${NC} $file"
        done
        echo ""
        echo "Make sure you're running this script from the niri-dots repository root."
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ All required files found${NC}"
    echo ""
}

# Function to install packages
install_packages() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would install: ${packages[*]}"
        return
    fi
    
    local packages=("$@")
    case $PKG_MANAGER in
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        apt)
            sudo apt update && sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y "${packages[@]}"
            ;;
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        zypper)
            sudo zypper install -y "${packages[@]}"
            ;;
        *)
            echo "Unsupported package manager. Please install manually:"
            echo "${packages[@]}"
            exit 1
            ;;
    esac
}

# Check and install dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local missing=()
    # Format: "package_name:binary_name"
    local packages=(
        "niri:niri"
        "waybar:waybar"
        "alacritty:alacritty"
        "fuzzel:fuzzel"
        "grim:grim"
        "slurp:slurp"
        "swaylock:swaylock"
        "swaybg:swaybg"
        "wl-clipboard:wl-copy"
        "libnotify:notify-send"
        "mako:mako"
        "networkmanager:nmcli"
        "bluez:bluetoothctl"
        "bluez-utils:bluetoothctl"
        "blueman:blueman-manager"
        "playerctl:playerctl"
        "brightnessctl:brightnessctl"
        "upower:upower"
    )

    for item in "${packages[@]}"; do
        IFS=':' read -r pkg bin <<< "$item"
        if ! command -v "$bin" &> /dev/null; then
            # Avoid duplicate package additions if multiple binaries map to same package
            if [[ ! " ${missing[*]} " =~ " ${pkg} " ]]; then
                missing+=("$pkg")
            fi
        else
            echo -e "  ${GREEN}✓${NC} $pkg (via $bin)"
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}Missing packages: ${missing[*]}${NC}"
        echo ""
        read -p "Install missing packages? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_packages "${missing[@]}"
            
            # Post-installation service setup
            if [[ " ${missing[*]} " =~ " bluetooth " ]] || [[ " ${missing[*]} " =~ " bluez " ]]; then
                echo -e "${YELLOW}Enabling bluetooth service...${NC}"
                sudo systemctl enable --now bluetooth || echo -e "${RED}Failed to enable bluetooth service${NC}"
            fi
        else
            echo "Skipping package installation."
        fi
    fi
}

# Install fonts
install_fonts() {
    echo ""
    echo -e "${YELLOW}Checking fonts...${NC}"
    
    # Check if JetBrainsMono Nerd Font is already installed
    if fc-list | grep -qi "jetbrains.*nerd"; then
        echo -e "  ${GREEN}✓${NC} JetBrainsMono Nerd Font already installed"
        return
    fi
    
    echo -e "  ${YELLOW}⚠${NC} JetBrainsMono Nerd Font not found"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would install fonts"
        return
    fi
    
    # Try to install from AUR
    if command -v paru &> /dev/null; then
        echo "Installing via paru..."
        paru -S --noconfirm ttf-jetbrains-mono-nerd || echo -e "${YELLOW}⚠${NC} Font installation failed"
    elif command -v yay &> /dev/null; then
        echo "Installing via yay..."
        yay -S --noconfirm ttf-jetbrains-mono-nerd || echo -e "${YELLOW}⚠${NC} Font installation failed"
    elif command -v git &> /dev/null; then
        echo "Installing JetBrainsMono Nerd Font manually..."
        mkdir -p "$HOME/.local/share/fonts/JetBrains"
        cd /tmp
        curl -L -o jetbrains-mono-nerd.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
        unzip -o jetbrains-mono-nerd.zip -d "$HOME/.local/share/fonts/JetBrains/"
        fc-cache -fv "$HOME/.local/share/fonts/"
        cd -
        echo -e "  ${GREEN}✓${NC} Fonts installed to ~/.local/share/fonts/"
    else
        echo -e "${YELLOW}Please install JetBrainsMono Nerd Font manually:${NC}"
        echo "  https://github.com/ryanoasis/nerd-fonts/releases"
    fi
}

# Create directories
create_directories() {
    echo ""
    echo -e "${YELLOW}Creating directories...${NC}"
    
    local dirs=(
        "$HOME/.config/niri"
        "$HOME/.config/alacritty"
        "$HOME/.config/fuzzel"
        "$HOME/.config/waybar"
        "$HOME/.local/bin"
        "$HOME/Pictures/Screenshots"
    )
    
    if [ "$DRY_RUN" = true ]; then
        for dir in "${dirs[@]}"; do
            echo -e "${BLUE}[DRY RUN]${NC} Would create: $dir"
        done
        echo -e "${BLUE}[DRY RUN]${NC} ✓ Directories would be created"
        return
    fi
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    echo "  ✓ Directories created"
}

# Link dotfiles
link_dotfiles() {
    echo ""
    echo -e "${YELLOW}Linking dotfiles...${NC}"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local errors=0
    
    # Define files to link
    # Define files and directories to link
    declare -A files=(
        ["$script_dir/.config/niri/config.kdl"]="$HOME/.config/niri/config.kdl"
        ["$script_dir/.config/alacritty/alacritty.toml"]="$HOME/.config/alacritty/alacritty.toml"
        ["$script_dir/.config/fuzzel/fuzzel.ini"]="$HOME/.config/fuzzel/fuzzel.ini"
        ["$script_dir/.config/waybar/config"]="$HOME/.config/waybar/config"
        ["$script_dir/.config/waybar/style.css"]="$HOME/.config/waybar/style.css"
        ["$script_dir/.config/waybar/launch.sh"]="$HOME/.config/waybar/launch.sh"
        ["$script_dir/.local/bin/screenshot-crop"]="$HOME/.local/bin/screenshot-crop"
        ["$script_dir/.local/bin/powermenu"]="$HOME/.local/bin/powermenu"
        ["$script_dir/.local/bin/waybar-toggle"]="$HOME/.local/bin/waybar-toggle"
        ["$script_dir/.local/bin/waybar-debug"]="$HOME/.local/bin/waybar-debug"
        ["$script_dir/.local/bin/waybar-test"]="$HOME/.local/bin/waybar-test"
        ["$script_dir/.local/bin/volume-control"]="$HOME/.local/bin/volume-control"
        ["$script_dir/.zshrc"]="$HOME/.zshrc"
    )
    
    # Define directories to link
    declare -A dirs=(
        ["$script_dir/.config/niri/wallpaper"]="$HOME/.config/niri/wallpaper"
    )
    
    # Link each file
    for src in "${!files[@]}"; do
        dst="${files[$src]}"
        
        # Check if source exists
        if [ ! -f "$src" ]; then
            echo -e "  ${RED}✗${NC} Source not found: $src"
            ((errors++))
            continue
        fi
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN]${NC} Would link: $src → $dst"
            continue
        fi
        
        # Backup existing config if it's not a symlink
        if [ -e "$dst" ] && [ ! -L "$dst" ]; then
            backup="$dst.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "  ${BLUE}→${NC} Backing up: $dst → $backup"
            mv "$dst" "$backup"
        fi
        
        # Create symlink
        ln -sf "$src" "$dst"
        echo -e "  ${GREEN}✓${NC} Linked: $(basename $dst)"
    done
    
    # Make scripts executable
    if [ "$DRY_RUN" = false ]; then
        if [ -f "$HOME/.local/bin/screenshot-crop" ]; then
            chmod +x "$HOME/.local/bin/screenshot-crop"
        fi
        if [ -f "$HOME/.local/bin/powermenu" ]; then
            chmod +x "$HOME/.local/bin/powermenu"
        fi
        if [ -f "$HOME/.local/bin/waybar-toggle" ]; then
            chmod +x "$HOME/.local/bin/waybar-toggle"
        fi
        if [ -f "$HOME/.local/bin/waybar-debug" ]; then
            chmod +x "$HOME/.local/bin/waybar-debug"
        fi
        if [ -f "$HOME/.local/bin/waybar-test" ]; then
            chmod +x "$HOME/.local/bin/waybar-test"
        fi
        if [ -f "$HOME/.local/bin/volume-control" ]; then
            chmod +x "$HOME/.local/bin/volume-control"
        fi
        if [ -f "$HOME/.config/waybar/launch.sh" ]; then
            chmod +x "$HOME/.config/waybar/launch.sh"
        fi
    fi
    
    # Link directories
    for src_dir in "${!dirs[@]}"; do
        dst_dir="${dirs[$src_dir]}"
        
        if [ ! -d "$src_dir" ]; then
            echo -e "  ${RED}✗${NC} Source directory not found: $src_dir"
            ((errors++))
            continue
        fi
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${BLUE}[DRY RUN]${NC} Would link directory: $src_dir → $dst_dir"
            continue
        fi
        
        # Backup existing directory if it's not a symlink
        if [ -e "$dst_dir" ] && [ ! -L "$dst_dir" ]; then
            backup="$dst_dir.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "  ${BLUE}→${NC} Backing up: $dst_dir → $backup"
            mv "$dst_dir" "$backup"
        fi
        
        # Create symlink
        ln -sf "$src_dir" "$dst_dir"
        echo -e "  ${GREEN}✓${NC} Linked directory: $(basename $dst_dir)"
    done
    
    if [ $errors -eq 0 ]; then
        echo ""
        echo -e "${GREEN}  ✓ All dotfiles linked successfully${NC}"
    else
        echo ""
        echo -e "${YELLOW}  ⚠ Completed with $errors errors${NC}"
    fi
}

# Setup wallpaper
setup_wallpaper() {
    echo ""
    echo -e "${YELLOW}Setting up wallpaper...${NC}"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config="$HOME/.config/niri/config.kdl"
    
    # Check if wallpaper is already configured in the config
    if grep -q "swaybg -i" "$config" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Wallpaper already configured in niri config"
        echo -e "  ${BLUE}→${NC} Edit ~/.config/niri/config.kdl to change it"
    else
        echo -e "  ${YELLOW}⚠${NC} No wallpaper configured"
        echo -e "  ${BLUE}→${NC} Edit ~/.config/niri/config.kdl to add your wallpaper:"
        echo "     spawn-sh-at-startup \"swaybg -i '/path/to/wallpaper.jpg' -m fill\""
    fi
}

# Create niri session file for SDDM
setup_session_file() {
    echo ""
    echo -e "${YELLOW}Setting up SDDM session...${NC}"
    
    local session_file="/usr/share/wayland-sessions/niri.desktop"
    
    if [ -f "$session_file" ]; then
        echo -e "  ${GREEN}✓${NC} Niri session file already exists"
        return
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${BLUE}[DRY RUN]${NC} Would create: $session_file"
        return
    fi
    
    echo -e "  ${BLUE}→${NC} Creating niri.desktop session file..."
    
    # Create session file with sudo
    sudo tee "$session_file" > /dev/null << 'EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri
Type=Application
EOF
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} Session file created at $session_file"
        echo -e "  ${BLUE}→${NC} Niri will appear in SDDM on next login"
    else
        echo -e "  ${RED}✗${NC} Failed to create session file"
        echo -e "  ${YELLOW}⚠${NC} Run manually with sudo:"
        echo "     sudo tee $session_file << 'EOF'"
        echo '     [Desktop Entry]'
        echo '     Name=Niri'
        echo '     Comment=A scrollable-tiling Wayland compositor'
        echo '     Exec=niri'
        echo '     Type=Application'
        echo '     EOF'
    fi
}

# Print summary
print_summary() {
    echo ""
    echo "=== Installation Complete ==="
    echo ""
    echo "Keybindings:"
    echo "  Mod+Return  - Alacritty terminal"
    echo "  Mod+B       - Firefox"
    echo "  Mod+D       - Fuzzel launcher"
    echo "  Mod+P       - Screenshot crop"
    echo "  Mod+W       - Fit window to screen"
    echo "  Mod+F       - Fullscreen"
    echo "  Mod+M       - Powermenu (Lockscreen, Logout, Shutdown)"
    echo "  Mod+Shift+Slash - Show hotkey overlay"
    echo "  Mod+Shift+T - Reload config"
    echo "  F11         - Volume down (with notification)"
    echo "  F12         - Volume up (with notification)"
    echo ""
    echo "Waybar:"
    echo "  Left: Workspaces, Media"
    echo "  Center: 12h time, date"
    echo "  Right: Tray (Bluetooth, WiFi), CPU %, RAM %, Battery"
    echo ""
    echo "Next steps:"
    echo "  1. Launch waybar: ~/.config/waybar/launch.sh (auto-detects Niri/Hyprland)"
    echo "  2. Reload config: Mod+Shift+T (from within niri)"
    echo "  3. Or restart session"
    echo "  4. Enjoy your new setup!"
    echo ""
    echo "To start Niri, log out and select Niri from your display manager."
    echo "Or run: niri"
}

# Main
main() {
    verify_structure
    
    if [ "$SKIP_DEPS" = false ]; then
        check_dependencies
    else
        echo -e "${YELLOW}Skipping dependency installation (--skip-deps)${NC}"
        echo ""
    fi
    
    if [ "$SKIP_FONTS" = false ]; then
        install_fonts
    else
        echo -e "${YELLOW}Skipping font installation (--skip-fonts)${NC}"
        echo ""
    fi
    
    create_directories
    link_dotfiles
    setup_wallpaper
    setup_session_file
    print_summary
}

main "$@"
