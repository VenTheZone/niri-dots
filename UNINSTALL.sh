#!/bin/bash
set -e

echo "=== Niri Dots Uninstallation ==="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root!${NC}"
    echo "Run as your regular user: ./UNINSTALL.sh"
    exit 1
fi

# Options
DRY_RUN=false
CONFIRM=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
            echo ""
            shift
            ;;
        -y|--yes)
            CONFIRM=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --dry-run     Show what would be done without making changes"
            echo "  -y, --yes    Skip confirmation prompt"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Check if symlinks exist
check_symlink() {
    if [ -L "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Remove symlink function
remove_symlink() {
    local target="$1"
    if check_symlink "$target"; then
        local link_target=$(readlink -f "$target")
        local is_niri_dots=0

        # Check if symlink points to niri-dots repo
        if [[ "$link_target" == *"niri-dots"* ]]; then
            is_niri_dots=1
        fi

        if [ $is_niri_dots -eq 1 ]; then
            if [ "$DRY_RUN" = false ]; then
                rm "$target"
                echo -e "  ${GREEN}✓${NC} Removed: $target"
            else
                echo -e "  ${BLUE}[DRY RUN]${NC} Would remove: $target"
            fi
            return 0
        else
            echo -e "  ${YELLOW}⊙${NC} Skipping (not niri-dots): $target"
            return 1
        fi
    fi
    return 1
}

# Remove backups function
remove_backups() {
    echo -e "${YELLOW}Checking for backups...${NC}"
    local backup_count=0

    for file in ~/.config/niri/config.kdl.backup* \
                 ~/.config/alacritty/alacritty.toml.backup* \
                 ~/.config/fuzzel/fuzzel.ini.backup* \
                 ~/.config/waybar/config.backup* \
                 ~/.config/waybar/style.css.backup* \
                 ~/.config/waybar/config.jsonc.backup* \
                 ~/.local/bin/screenshot-crop.backup* \
                 ~/.local/bin/powermenu.backup* \
                 ~/.zshrc.backup*; do
        if [ -f "$file" ]; then
            if [ "$DRY_RUN" = false ]; then
                rm "$file"
                echo -e "  ${GREEN}✓${NC} Removed backup: $file"
            else
                echo -e "  ${BLUE}[DRY RUN]${NC} Would remove: $file"
            fi
            ((backup_count++))
        fi
    done

    if [ $backup_count -eq 0 ]; then
        echo "  No backups found"
    else
        echo "  Removed $backup_count backup(s)"
    fi
}

# Main uninstall process
uninstall() {
    echo -e "${YELLOW}Removing dotfile symlinks...${NC}"
    echo ""

    local removed=0

    # Config symlinks
    remove_symlink ~/.config/niri/config.kdl && ((removed++)) || true
    remove_symlink ~/.config/alacritty/alacritty.toml && ((removed++)) || true
    remove_symlink ~/.config/fuzzel/fuzzel.ini && ((removed++)) || true
    remove_symlink ~/.config/waybar/config && ((removed++)) || true
    remove_symlink ~/.config/waybar/style.css && ((removed++)) || true

    # Bin symlinks
    remove_symlink ~/.local/bin/screenshot-crop && ((removed++)) || true
    remove_symlink ~/.local/bin/powermenu && ((removed++)) || true
    remove_symlink ~/.local/bin/waybar-toggle && ((removed++)) || true
    remove_symlink ~/.local/bin/waybar-debug && ((removed++)) || true
    remove_symlink ~/.local/bin/waybar-test && ((removed++)) || true

    # Zshrc symlink
    remove_symlink ~/.zshrc && ((removed++)) || true

    echo ""
    echo -e "Removed $removed symlink(s) linked to niri-dots"
    echo ""

    # Remove backups
    remove_backups
}

# Confirmation
if [ "$CONFIRM" = false ] && [ "$DRY_RUN" = false ]; then
    echo -e "${RED}This will remove all niri-dots symlinks from your home directory.${NC}"
    echo ""
    read -p "Are you sure? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi
    echo ""
fi

# Run uninstall
uninstall

echo ""
echo "=== Uninstallation Complete ==="
echo ""
echo "What's left:"
echo "  - Original niri-dots repository (if you want to keep it)"
echo "  - Any config files that were not symlinks"
echo ""
echo "To restore a previous backup, you can copy files from backup locations:"
echo "  ~/.config/niri/config.kdl.backup.*"
echo ""
echo "Note: If you want a clean slate, you may need to:"
echo "  1. Log out of Niri"
echo "  2. Manually delete any remaining config files"
echo "  3. Log back in (will use defaults)"
