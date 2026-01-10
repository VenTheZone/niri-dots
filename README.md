# Niri Dots

Cyberpunk-themed Niri configuration with Waybar, Alacritty, and Fuzzel.

## Components

- **Niri**: Window manager with hotkey overlay (`Mod+Shift+Slash`)
- **Waybar**: Floating modular status bar (toggle with `Mod+Shift+B`)
- **Alacritty**: Terminal with cyberpunk color scheme
- **Fuzzel**: App launcher
- **Screenshot**: Crop tool (`Mod+P`) with auto-naming
- **Powermenu**: Lockscreen, Logout, Shutdown (`Mod+Shift+M`)

## Waybar Layout (Floating Pieces)

| Left | Center | Right |
|------|--------|-------|
| Workspaces (1-5) | Clock (HH:MM) | Tray |
| | | Network |
| | | Bluetooth |
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
| `Mod+Shift+B` | Toggle waybar |
| `Mod+Shift+M` | Powermenu |
| `Mod+Shift+Slash` | Show hotkey overlay |
| `Mod+Shift+T` | Reload config |
| `Mod+Shift+Q` | Close window |

## Installation

### Quick Install

```bash
git clone https://github.com/YOUR_USER/niri-dots.git ~/.config/niri-dots
cd ~/.config/niri-dots
./install.sh
```

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
