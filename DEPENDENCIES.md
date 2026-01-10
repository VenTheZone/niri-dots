# Niri Dots Dependencies

## Core Packages

| Package | Description | Required |
|---------|-------------|----------|
| `niri` | Dynamic tiling Wayland compositor | Yes |
| `waybar` | Status bar for Wayland | Yes |
| `alacritty` | GPU-accelerated terminal emulator | Yes |
| `fuzzel` | Wayland application launcher | Yes |
| `grim` | Screenshot utility for Wayland | Yes |
| `slurp` | Select a region in a Wayland compositor | Yes |
| `swaylock` | Screen locker for Wayland | Yes |
| `wl-clipboard` | Clipboard utilities for Wayland | Yes |
| `libnotify` | Desktop notification library | Yes |

## Waybar Modules

| Package | Description | Required |
|---------|-------------|----------|
| `networkmanager` | Network management | Yes |
| `bluez` | Bluetooth daemon | Yes |
| `bluez-utils` | Bluetooth utilities (`bluetoothctl`) | Yes |

## Optional Packages

| Package | Description | Required |
|---------|-------------|----------|
| `nerd-fonts-jetbrains-mono` | JetBrainsMono Nerd Font | Yes |
| `firefox` | Web browser | No |

## Installation

### Arch Linux

```bash
# Core packages
sudo pacman -S niri waybar alacritty fuzzel grim slurp swaylock wl-clipboard libnotify networkmanager bluez

# AUR packages
paru -S nerd-fonts-jetbrains-mono
# or
yay -S nerd-fonts-jetbrains-mono
```

### Debian/Ubuntu

```bash
sudo apt update
sudo apt install niri waybar alacritty grim slurp swaylock wl-clipboard libnotify network-manager bluez

# Fuzzel may need to be built from source or from third-party repos
# JetBrainsMono Nerd Font
mkdir -p ~/.fonts
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.tar.xz -o /tmp/JetBrainsMono.tar.xz
tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.fonts/
fc-cache -fv
```

### Fedora

```bash
sudo dnf install niri waybar alacritty grim slurp wl-clipboard libnotify NetworkManager bluez

# Fuzzel and swaylock may need RPM Fusion
sudo dnf install swaylock

# Build fuzzel from source if needed
```

## Font

- **JetBrainsMono Nerd Font** - Required for proper rendering of icons and text
- Installation: `nerd-fonts-jetbrains-mono` package on Arch, or download from [Nerd Fonts](https://www.nerdfonts.com/)

## Hyprland Compatibility

These dots are designed for Niri. If you're using Hyprland, many bindings can be adapted:
- `swaylock` works on both
- `grim` and `slurp` work on both
- `fuzzel` works on both
- `waybar` works on both (configuration differs slightly)
