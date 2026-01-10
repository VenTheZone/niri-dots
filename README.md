# Niri Dots <img src="https://img.shields.io/badge/Niri-Wayland-cyan?style=flat-square" alt="Niri" /> <img src="https://img.shields.io/badge/Theme-Cyberpunk-magenta?style=flat-square" alt="Theme" /> <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" /> <img src="https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white" alt="Shell" />

Cyberpunk-themed Niri configuration with Waybar, Alacritty, and Fuzzel.

## Features

- 🚀 **Fast Tiling WM** - Niri's scrollable column-based layout
- 🎨 **Cyberpunk Theme** - Neon colors with transparent effects
- ⌨️ **Comprehensive Keybinds** - Easy-to-use keyboard shortcuts
- 🔧 **Easy Installation** - One-command setup with dependency management
- 📊 **Modular Status Bar** - Workspaces, system info, media controls
- 📸 **Screenshot Tool** - Region selection with auto-naming
- 🔌 **Power Menu** - Quick access to lock/logout/shutdown

## Table of Contents

- [Components](#components)
- [Screenshots](#screenshots)
- [Keybindings](#keybindings)
- [Installation](#installation)
- [Requirements](#requirements)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)

## Components

- **Niri**: Window manager with hotkey overlay (`Mod+Shift+Slash`)
- **Waybar**: Floating modular status bar (toggle with `Mod+Shift+B`)
- **Alacritty**: Terminal with cyberpunk color scheme
- **Fuzzel**: App launcher
- **Screenshot**: Crop tool (`Mod+P`) with auto-naming
- **Powermenu**: Lockscreen, Logout, Shutdown (`Mod+Shift+M`)

## Screenshots

![Desktop Screenshot](screenshots/desktop.png?raw=true)

*Screenshots will be added here - Feel free to contribute yours!*

## Waybar Layout (Floating Pieces)

| Left | Center | Right |
|------|--------|-------|
| Workspaces (1-5) | Clock (HH:MM) | Tray |
| Now Playing | | Network |
| | | Bluetooth |
| | | Battery |
| | | CPU |
| | | Memory |

## Keybindings

| Key | Action |
|-----|--------|
| `Mod+Return` | Open Alacritty |
| `Mod+B` | Open Firefox |
| `Mod+D` | Open Fuzzel |
| `Mod+P` | Screenshot crop |
| `Mod+W` | Fit window to screen |
| `Mod+F` | Fullscreen |
| `Mod+M` | Fit to edges |
| `Mod+Shift+B` | Toggle waybar |
| `Mod+Shift+M` | Powermenu |
| `Mod+Shift+Slash` | Show hotkey overlay |
| `Mod+Shift+T` | Reload config |
| `Mod+Shift+Q` | Close window |
| `XF86AudioPlay` | Play/Pause media |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute audio |
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |

## Installation

### Quick Install

```bash
git clone https://github.com/YOUR_USER/niri-dots.git ~/.config/niri-dots
cd ~/.config/niri-dots
./install.sh
```

### Install Options

The installer supports several options:

```bash
# Skip dependency installation (if you already have everything)
./install.sh --skip-deps

# Skip font installation
./install.sh --skip-fonts

# Preview what would be done without making changes
./install.sh --dry-run

# Combine options
./install.sh --skip-deps --skip-fonts

# Show help
./install.sh -h
```

### What the Installer Does

1. **Verifies** all required files exist
2. **Installs** dependencies (niri, waybar, alacritty, fuzzel, etc.)
3. **Installs** JetBrainsMono Nerd Font
4. **Creates** necessary directories
5. **Links** all configuration files to your home directory
6. **Backs up** existing configs before overwriting
7. **Sets up** wallpaper configuration

### Manual Installation

```bash
git clone https://github.com/YOUR_USER/niri-dots.git ~/.config/niri-dots
cd ~/.config/niri-dots
stow .
```

Then log out and select Niri from your display manager.

## Requirements

See [DEPENDENCIES.md](./DEPENDENCIES.md) for full list.

- Niri, Waybar, Alacritty, Fuzzel
- Grim + Slurp (for screenshots)
- Swaylock (for lockscreen)
- JetBrainsMono Nerd Font

## Troubleshooting

### Wallpaper Not Showing

1. Ensure the wallpaper file exists at the configured path
2. Check if `swaybg` is installed and running: `ps aux | grep swaybg`
3. If using a custom wallpaper path, update `~/.config/niri/config.kdl`:
   ```kdl
   spawn-sh-at-startup "swaybg -i '/path/to/your/wallpaper.jpg' -m fill"
   ```
4. Reload config: `Mod+Shift+T`

### Keybinds Not Working

1. Make sure the niri config is symlinked correctly:
   ```bash
   ls -la ~/.config/niri/config.kdl
   ```
2. Should show a symlink to your niri-dots repo
3. If not, run the installer again or manually symlink:
   ```bash
   ln -s /path/to/niri-dots/.config/niri/config.kdl ~/.config/niri/config.kdl
   ```
4. Reload config: `Mod+Shift+T`

### Title Bars Still Visible

The `prefer-no-csd` setting in `config.kdl` removes title bars. If you still see them:
1. Some apps ignore this setting (try them in other apps)
2. Check the app's own settings for window decorations
3. For Firefox: Go to Settings → General → Customization → "Title bar" (uncheck)

### Waybar Not Showing

1. Check if waybar is running: `ps aux | grep waybar`
2. If not, restart it manually: `waybar`
3. Check for errors: `waybar -c ~/.config/waybar/config -s ~/.config/waybar/style.css`
4. Toggle with: `Mod+Shift+B`

### Reinstalling

To start fresh:
```bash
# Remove existing symlinks
rm ~/.config/niri/config.kdl
rm ~/.config/alacritty/alacritty.toml
rm ~/.config/fuzzel/fuzzel.ini
rm ~/.config/waybar/config
rm ~/.config/waybar/style.css
rm ~/.local/bin/screenshot-crop
rm ~/.local/bin/powermenu
rm ~/.zshrc

# Run installer again
cd ~/path/to/niri-dots
./install.sh
```

## Uninstallation

To completely remove niri-dots:

```bash
cd ~/path/to/niri-dots
./UNINSTALL.sh
```

The uninstall script will:
- ✅ Remove all symlinks linked to niri-dots
- ✅ Remove all backup files
- ✅ Keep the niri-dots repository (for later use)
- ✅ Warn before making any changes

Options:
```bash
./UNINSTALL.sh --dry-run    # Preview changes without making them
./UNINSTALL.sh -y            # Skip confirmation prompt
./UNINSTALL.sh -h            # Show help
```
