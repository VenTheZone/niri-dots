#!/bin/bash
set -e

echo "=== Niri Dots Installation ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

# Function to install packages
install_packages() {
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
    local packages=(
        "niri"           # Window manager
        "waybar"         # Status bar
        "alacritty"      # Terminal
        "fuzzel"         # App launcher
        "grim"           # Screenshot utility
        "slurp"          # Region selection
        "swaylock"       # Lockscreen
        "wl-clipboard"   # Clipboard utilities
        "libnotify"      # Notifications
        "networkmanager" # Network management
        "bluez"          # Bluetooth
    )

    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            missing+=("$pkg")
        else
            echo -e "  ${GREEN}✓${NC} $pkg"
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
        else
            echo "Skipping package installation."
        fi
    fi
}

# Install fonts
install_fonts() {
    echo ""
    echo -e "${YELLOW}Installing fonts...${NC}"
    
    if ! command -v paru &> /dev/null && ! command -v yay &> /dev/null; then
        # Try to install from AUR if available
        if command -v git &> /dev/null; then
            echo "Installing JetBrainsMono Nerd Font from AUR..."
            cd /tmp
            git clone https://aur.archlinux.org/nerd-fonts-jetbrains-mono.git
            cd nerd-fonts-jetbrains-mono
            makepkg -si --noconfirm
            cd -
        else
            echo "Git not found. Please install JetBrainsMono Nerd Font manually."
        fi
    else
        # Use AUR helper if available
        if command -v paru &> /dev/null; then
            paru -S --noconfirm nerd-fonts-jetbrains-mono
        elif command -v yay &> /dev/null; then
            yay -S --noconfirm nerd-fonts-jetbrains-mono
        fi
    fi
}

# Create directories
create_directories() {
    echo ""
    echo -e "${YELLOW}Creating directories...${NC}"
    
    mkdir -p ~/.config/niri
    mkdir -p ~/.config/alacritty
    mkdir -p ~/.config/fuzzel
    mkdir -p ~/.config/waybar
    mkdir -p ~/.local/bin
    mkdir -p ~/Pictures/Screenshots
    
    echo "  ✓ Directories created"
}

# Link dotfiles
link_dotfiles() {
    echo ""
    echo -e "${YELLOW}Linking dotfiles...${NC}"
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    ln -sf "$script_dir/.config/niri/config.kdl" ~/.config/niri/config.kdl
    ln -sf "$script_dir/.config/alacritty/alacritty.toml" ~/.config/alacritty/alacritty.toml
    ln -sf "$script_dir/.config/fuzzel/fuzzel.ini" ~/.config/fuzzel/fuzzel.ini
    ln -sf "$script_dir/.config/waybar/config" ~/.config/waybar/config
    ln -sf "$script_dir/.config/waybar/style.css" ~/.config/waybar/style.css
    ln -sf "$script_dir/.local/bin/screenshot-crop" ~/.local/bin/screenshot-crop
    ln -sf "$script_dir/.local/bin/powermenu" ~/.local/bin/powermenu
    ln -sf "$script_dir/.zshrc" ~/.zshrc
    
    chmod +x ~/.local/bin/screenshot-crop
    chmod +x ~/.local/bin/powermenu
    
    echo "  ✓ Dotfiles linked"
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
    echo ""
    echo "Waybar:"
    echo "  Left: Workspaces, Active window"
    echo "  Center: 12h time, date"
    echo "  Right: Bluetooth, WiFi, Battery, Tray"
    echo ""
    echo "To start Niri, log out and select Niri from your display manager."
    echo "Or run: niri"
}

# Main
main() {
    check_dependencies
    install_fonts
    create_directories
    link_dotfiles
    print_summary
}

main "$@"
