# Niri Dots Dependencies

`./install.sh` checks all of these, installs missing required packages with pacman,
offers the optional ones, and installs AUR packages through paru/yay when available.
`./install.sh --check` prints what is missing without changing anything.

## Required

| Package | Used by |
|---------|---------|
| `niri` | Compositor |
| `quickshell` | Poster wallpaper, wallpaper dial, CRT lock screen, music player, volume pill |
| `qt6-multimedia`, `qt6-multimedia-ffmpeg` | Video channels on the lock screen TV |
| `waybar` | Status bar |
| `alacritty` | David terminal |
| `fuzzel` | Launcher, clipboard/wifi/audio menus |
| `mako`, `libnotify` | Notifications |
| `swaylock` | Fallback lock screen |
| `swaybg` | Fallback wallpaper when Quickshell is missing |
| `awww` | Animated wave behind the overview |
| `grim`, `slurp` | Screenshots |
| `wf-recorder` | Screen recording |
| `wl-clipboard`, `cliphist` | Clipboard history |
| `pipewire` (`wpctl`), `libpulse` (`pactl`) | Volume and device switching |
| `playerctl` | Media keys, waybar media module |
| `brightnessctl` | Brightness keys |
| `upower` | Battery module |
| `networkmanager`, `bluez`, `blueman` | Network and Bluetooth |
| `jq`, `bc`, `curl`, `unzip`, `git` | Scripts and installer |
| `zsh`, `fzf` | Shell (`.zshrc`, forgit) |

## Optional

| Package | Used by |
|---------|---------|
| `kitty` | Lucy terminal |
| `dolphin` | File manager (`Mod+E`) |
| `plasma-integration`, `plasma-workspace` | Edgerunners KDE colour scheme for Qt apps |
| `yazi`, `btop`, `fastfetch` | Themed terminal tools |
| `mpv` | Floating video player rule |
| `papirus-icon-theme` | Fuzzel icons |
| `asusctl` | Keyboard backlight (ASUS laptops) |
| `sddm` | CRT TV login theme (`./install.sh --sddm`) |

## AUR (optional)

| Package | Used by |
|---------|---------|
| `zen-browser-bin` | Browser (`Mod+B`), themed with `userChrome.css` |
| `vesktop` | Discord client, themed with `edgerunners.theme.css` |
| `beautyline` | GTK icon theme |

## Fonts (installed by `install.sh`)

| Font | Source | Used by |
|------|--------|---------|
| JetBrainsMono Nerd Font | `ttf-jetbrains-mono-nerd` | Alacritty, waybar, fuzzel, mako |
| Symbols Nerd Font | `ttf-nerd-fonts-symbols` | Kitty powerline glyphs |
| Maple Mono | GitHub release download | Kitty |
| Abril Fatface, Silkscreen | Bundled in `.config/quickshell/fonts` | Poster names, pixel UI |

## Shell (cloned by `install.sh`)

oh-my-zsh, powerlevel10k (config in `.p10k.zsh`), zsh-autosuggestions, zsh-syntax-highlighting,
zsh-completions, zsh-history-substring-search, forgit.

## Bundled themes

- `Edgerunners` cursor (`.local/share/icons/Edgerunners`)
- `Edge-Runner` GTK theme (Flat Remix GTK Yellow Darkest, GPL-3.0, `.local/share/themes/Edge-Runner`)
- `Edgerunners` KDE colour scheme (`.local/share/color-schemes`)

## Manual install (Arch)

```bash
sudo pacman -S --needed niri quickshell qt6-multimedia qt6-multimedia-ffmpeg waybar alacritty fuzzel \
  mako libnotify swaylock swaybg awww grim slurp wf-recorder wl-clipboard cliphist pipewire libpulse \
  playerctl brightnessctl upower networkmanager bluez blueman jq bc curl unzip git zsh fzf \
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
paru -S zen-browser-bin vesktop beautyline   # optional
```
