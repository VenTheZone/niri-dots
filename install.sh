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
    local packages=(
        "niri"           # Window manager
        "waybar"         # Status bar
        "alacritty"      # Terminal
        "fuzzel"         # App launcher
        "grim"           # Screenshot utility
        "slurp"          # Region selection
        "swaylock"       # Lockscreen
        "swaybg"         # Wallpaper
        "wl-clipboard"   # Clipboard utilities
        "libnotify"      # Notifications
        "networkmanager" # Network management
        "bluez"          # Bluetooth daemon
        "bluez-utils"    # Bluetooth CLI tools
        "blueman"        # Bluetooth GUI
        "playerctl"      # Media control
        "brightnessctl"  # Brightness control
        "upower"         # Battery management
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
    declare -A files=(
        ["$script_dir/.config/niri/config.kdl"]="$HOME/.config/niri/config.kdl"
        ["$script_dir/.config/alacritty/alacritty.toml"]="$HOME/.config/alacritty/alacritty.toml"
        ["$script_dir/.config/fuzzel/fuzzel.ini"]="$HOME/.config/fuzzel/fuzzel.ini"
        ["$script_dir/.config/waybar/config"]="$HOME/.config/waybar/config"
        ["$script_dir/.config/waybar/style.css"]="$HOME/.config/waybar/style.css"
        ["$script_dir/.local/bin/screenshot-crop"]="$HOME/.local/bin/screenshot-crop"
        ["$script_dir/.local/bin/powermenu"]="$HOME/.local/bin/powermenu"
        ["$script_dir/.local/bin/waybar-toggle"]="$HOME/.local/bin/waybar-toggle"
        ["$script_dir/.local/bin/waybar-debug"]="$HOME/.local/bin/waybar-debug"
        ["$script_dir/.local/bin/waybar-test"]="$HOME/.local/bin/waybar-test"
        ["$script_dir/.zshrc"]="$HOME/.zshrc"
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
    fi
    
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
    local default_wallpaper="$HOME/Downloads/Rap Musik.jpg"
    local config="$script_dir/.config/niri/config.kdl"
    
    if [ -f "$default_wallpaper" ]; then
        echo -e "  ${GREEN}✓${NC} Found wallpaper: $default_wallpaper"
        echo -e "  ${BLUE}→${NC} Configured in niri config"
    else
        echo -e "  ${YELLOW}⚠${NC} Default wallpaper not found: $default_wallpaper"
        
        if [ "$DRY_RUN" = false ]; then
            echo ""
            read -p "Enter path to your wallpaper (or press Enter to skip): " wallpaper_path
            
            if [ -n "$wallpaper_path" ] && [ -f "$wallpaper_path" ]; then
                echo -e "  ${GREEN}✓${NC} Using: $wallpaper_path"
                # Escape spaces for shell command
                escaped_path=$(printf '%s\n' "$wallpaper_path" | sed 's/"/\\"/g' | sed "s/'/'\\\\''/g")
                sed -i "s|spawn-sh-at-startup \"swaybg -i '/home/JT/Downloads/Rap Musik.jpg' -m fill\"|spawn-sh-at-startup \"swaybg -i '$escaped_path' -m fill\"|" "$config"
                echo -e "  ${GREEN}✓${NC} Updated config with new wallpaper"
            else
                echo -e "  ${YELLOW}⚠${NC} Wallpaper not set. Edit ~/.config/niri/config.kdl manually."
            fi
        else
            echo -e "${BLUE}[DRY RUN]${NC} Would prompt for wallpaper path"
        fi
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
    echo ""
    echo "Waybar:"
    echo "  Left: Workspaces, Active window"
    echo "  Center: 12h time, date"
    echo "  Right: Bluetooth, WiFi, Battery, Tray"
    echo ""
    echo "Next steps:"
    echo "  1. Reload config: Mod+Shift+T (from within niri)"
    echo "  2. Or restart niri session"
    echo "  3. Enjoy your new setup!"
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
    print_summary
}

main "$@"
