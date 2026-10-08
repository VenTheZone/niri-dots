# Niri Dots <img src="https://img.shields.io/badge/Niri-Wayland-cyan?style=flat-square" alt="Niri" /> <img src="https://img.shields.io/badge/Quickshell-QML-f3e600?style=flat-square" alt="Quickshell" /> <img src="https://img.shields.io/badge/Theme-Edgerunners-ff2a9d?style=flat-square" alt="Theme" /> <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />

A Cyberpunk: Edgerunners rice for the [niri](https://github.com/YaLTeR/niri) compositor. The desktop is a
character poster in an inverted duotone; your mouse is a flashlight that shows the real colours,
a radial dial swaps posters, and the lock screen is an old CRT TV flipping through anime loops.

## Highlights

- **Poster wallpaper**: 14 Edgerunners / Cyberpunk 2077 posters, each with its own accent colour and huge serif name.
  Hover to reveal colours under the cursor, click to flip the whole poster with a glitch.
- **Wallpaper dial**: radial picker with fade, wipe, grow, outer, clock or random transitions.
- **CRT lock screen**: a TV in a dark room playing video/GIF channels, live clock, zoom-into-the-tube unlock.
- **Music player**: halftone overlay with spinning album art and a zigzag seek bar.
- **Matching apps**: waybar pills, fuzzel, mako, Dolphin/Qt, GTK, yazi, btop, fastfetch, kitty, alacritty, Zen, Vesktop.
- **Login screen** (optional): the same CRT TV as an SDDM theme.
- **Installer** with a jack-in animation that detects your distro, checks packages, and links everything.

## Install

```bash
git clone https://github.com/VenTheZone/niri-dots.git ~/.config/niri-dots
cd ~/.config/niri-dots
./install.sh
```

Then log out and pick **Niri** at your login screen.

| Option | What it does |
|--------|--------------|
| `--check` | Preflight only: distro, packages, conflicts. Changes nothing |
| `--dry-run` | Show every step without making changes |
| `--sddm` | Also install the CRT TV login theme (needs sudo) |
| `--skip-deps` / `--skip-fonts` | Skip package or font installation |
| `--yes` | Answer yes to prompts (non-interactive) |
| `--no-anim` | Skip the jack-in animation |

### Distro support

The installer reads `/etc/os-release` and maps package names for your distro family. Anything your
repos don't ship is listed with an install hint instead of failing.

| Family | Status |
|--------|--------|
| Arch, EndeavourOS, CachyOS, Manjaro, Garuda | Full: everything installs from pacman, AUR extras via paru/yay |
| Fedora | Best effort: Quickshell from COPR, awww built by hand |
| Debian, Ubuntu, Mint, Pop | Best effort: niri, Quickshell and awww built by hand |
| openSUSE | Best effort |

Full package list: [DEPENDENCIES.md](./DEPENDENCIES.md).

### What the installer does

1. Checks distro family, kernel, systemd and Wayland
2. Verifies every file it is about to link exists in the repo
3. Detects conflicts (foreign symlinks, a stray waybar `config.jsonc`, replacing `.zshrc`)
4. Installs required packages, offers optional and AUR ones
5. Installs fonts: JetBrainsMono Nerd, Symbols Nerd, Maple Mono
6. Links configs, scripts, wallpapers (posters + TV clips), GTK theme, pointer theme and KDE colour scheme, backing up anything it replaces
7. Clones oh-my-zsh, powerlevel10k and the plugins `.zshrc` uses
8. Applies the Qt colour scheme, btop theme and Zen `userChrome.css`
9. With `--sddm`, installs and selects the CRT login theme

## Using it

### Poster wallpaper

| Input | Action |
|-------|--------|
| Hover the desktop | Flashlight reveal around the pointer |
| Left-click desktop / `Mod+Alt+R` | Flip the whole poster to real colours |
| Right-click desktop / `Mod+Alt+W` | Open the wallpaper dial |
| `Mod+Alt+N` | Next poster |

In the dial: arrows, `H`/`J`/`K`/`L` or scroll rotate it, `Tab` changes the transition, `Enter` applies,
`Esc` or a click outside closes it.

### Lock screen

`Mod+Shift+L` (or the power menu). Type your password and press `Enter`; `Up`/`Down` flip TV channels.
If Quickshell isn't running, swaylock takes over.

### Music player

`Mod+Alt+M`, or right-click the media module in waybar. `Space` play/pause, `←`/`→` skip, click the
zigzag bar to seek, `Esc` closes. Works with any MPRIS player.

### Keybindings

Press `Mod+Shift+/` for the full list in niri.

| Key | Action |
|-----|--------|
| `Mod+Return` | Kitty (Lucy theme) |
| `Mod+Backspace` | Alacritty (David theme) |
| `Mod+D` | Launcher (fuzzel in the poster's accent) |
| `Mod+B` | Zen browser |
| `Mod+E` | Dolphin |
| `Mod+Alt+W` / `Mod+Alt+R` / `Mod+Alt+N` | Wallpaper dial / reveal / next poster |
| `Mod+Alt+M` | Music player |
| `Mod+Shift+L` | Lock screen |
| `Mod+Shift+M` | Power menu |
| `Mod+Shift+V` | Clipboard history |
| `Mod+P` / `Mod+Alt+P` / `Print` | Region / window / screen screenshot |
| `Mod+Print` | Toggle screen recording (MP4 in `~/Videos`) |
| `Mod+O` | Overview |
| `Mod+H` / `Mod+L` | Focus column left / right |
| `Mod+J` / `Mod+K` | Workspace down / up |
| `Mod+Ctrl+H` / `Mod+Ctrl+L` | Move column left / right |
| `Mod+1`…`Mod+5` | Go to workspace |
| `Mod+F` / `Mod+W` / `Mod+M` | Fullscreen / maximize column / maximize to edges |
| `Mod+V` | Toggle floating |
| `Mod+Shift+Q` | Close window |
| `Mod+Shift+B` | Toggle waybar |
| `Mod+Shift+T` | Reload niri config |
| `F10` / `F11` / `F12` | Mute / volume down / volume up |
| `Mod+Shift+F10` | Switch audio output |

## Customising

- **Posters**: drop an image in `.config/niri/wallpaper/posters/` and add it to `posters.json`
  (`file`, `name`, `tag`, `accent`). The dial picks it up live.
- **TV channels**: anything in `.config/niri/wallpaper/tv/` (mp4, webm, mkv, mov, gif, webp, png, jpg).
- **Shaders**: `.config/quickshell/shaders/*.frag`; rebuild with the `qsb` command at the top of each file.
- **Shell code**: `.config/quickshell/` (`Rice.qml` holds state and IPC; one file per surface).

Quickshell can be driven from scripts: `qs ipc show` lists everything, e.g. `qs ipc call wall next`.

## Repo layout

```
.config/quickshell/     wallpaper, dial, lock screen, music player, volume pill (QML + shaders + fonts)
.config/niri/           niri config; wallpaper/{posters,tv} hold the art and clips
.config/waybar/         bar config, pill styling, scripts
.config/{kitty,alacritty,fuzzel,mako,yazi,btop,fastfetch,swaylock,zen,vesktop}/
.local/share/           pointer theme, GTK theme, KDE colour scheme
.local/bin/             screenshot, recording, power, clipboard, audio helpers
sddm/edgerunners-crt/   login theme (installed with --sddm)
```

## Troubleshooting

**No poster wallpaper.** Check Quickshell is running: `qs list`. Start it with `qs -d`; errors show in `qs log`.

**Locked out with a blank or red screen.** That's niri holding a lock whose lock screen died. Switch to a
TTY (`Ctrl+Alt+F3`), log in, and run `WAYLAND_DISPLAY=wayland-1 swaylock`, then go back
(`Ctrl+Alt+F1` or `F2`) and unlock. Don't run `qs kill` while locked; `qs ipc call lock isLocked` tells you.

**Waybar missing.** Run `waybar` from a terminal to see errors; `Mod+Shift+B` toggles it.

**Keybinds do nothing.** `ls -la ~/.config/niri/config.kdl` should point into this repo; re-run `./install.sh`.

**Dolphin isn't themed.** It needs `plasma-integration` and a new login (for `QT_QPA_PLATFORMTHEME=kde`).

## Uninstall

```bash
./UNINSTALL.sh          # removes the symlinks, keeps the repo
./UNINSTALL.sh --dry-run
```

## Credits

- Posters from [wallhaven](https://wallhaven.cc), TV loops from [MoeWalls](https://moewalls.com); characters belong to CD PROJEKT RED / Studio Trigger
- Fonts: [Abril Fatface](https://fonts.google.com/specimen/Abril+Fatface) and [Silkscreen](https://fonts.google.com/specimen/Silkscreen) (OFL)
- GTK theme: [Flat Remix GTK](https://github.com/daniruiz/flat-remix-gtk) (GPL-3.0), bundled as Edge-Runner
- Vesktop theme built on [midnight-discord](https://github.com/refact0r/midnight-discord)
- Inspired by Zenless Zone Zero style poster desktops

## License

MIT for the configs and scripts; bundled art, fonts and themes keep their own licenses.
