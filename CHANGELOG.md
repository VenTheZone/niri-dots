# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Quickshell poster wallpaper: inverted duotone in the poster's accent, cursor flashlight reveals the real colours, click or `Mod+Alt+R` flips the whole thing with a glitch; Abril Fatface faction/name typography
- Fourteen Edgerunners / Cyberpunk 2077 posters (`wallpaper/posters/` + `posters.json` for name, tag, accent)
- Radial wallpaper dial (`Mod+Alt+W` or right-click the desktop) with fade/wipe/grow/outer/clock/random transitions
- CRT TV lock screen (`Mod+Shift+L`): channels from `wallpaper/tv/` (video, gif or image; nine Edgerunners loops shipped), `Up`/`Down` to flip, live 12h clock with seconds and date on the glass, scanlines, zoom-into-the-tube unlock; falls back to swaylock
- Quickshell file watching is paused while locked, a hot-reload mid-lock otherwise crashes the lock
- Lock screen rotates between two looks every 30s, diving into / out of the TV to swap: Neon Room (rainy city window, flickering `NIGHT CITY` neon sign) and a full-screen Netrunner HUD (channel through the CRT shader, battery/Wi-Fi/uptime/now-playing readouts, data ticker, `ACCESS CODE` prompt)
- Lock screen wrong-password ERROR screen (pixel skull, red strobe, shake) and right-password BREACH PROTOCOL → ACCESS GRANTED → CRT switch-off
- Lock screen shows PAM's own message, e.g. a faillock lockout with the minutes left
- Left-edge volume pill OSD (Pipewire)
- Music player overlay (`Mod+Alt+M`): halftone backdrop in the poster accent, spinning album art, zigzag seek bar, kaomoji
- Edgerunners KDE colour scheme (Dolphin/Qt), yazi, btop, fastfetch (live poster logo), Zen `userChrome.css`, Vesktop theme (midnight-discord base)
- SDDM `edgerunners-crt` login theme mirroring the lock screen (`./install.sh --sddm`)
- `qs ipc call lock isLocked` so scripts can avoid restarting the shell mid-lock
- Installer: jack-in animation (CRT power-on, glitch-decoded logo, staged progress, `--no-anim`), distro-family detection with per-family package names, repo availability checks and install hints, optional + AUR package installs, Maple Mono / Nerd font installs, oh-my-zsh + powerlevel10k setup
- Bundled Edge-Runner GTK theme, `.p10k.zsh`, Qt platform theme env, every waybar script and `audio-switch` now linked
- Fuzzel restyled like the wallpaper dial and launched through Quickshell (`Mod+D`, waybar launcher) so border, selection and matches take the current poster's accent; config sections fixed (layout/border keys were sitting under `[colors]` and being rejected)
- Kitty Lucy theme (`kitty.conf` + `dark-theme.auto.conf`) with visible magenta cursor trail
- Edgerunners XCursor theme (CP yellow fill, cyan glow) plus `default` inherit so `XCURSOR_THEME=default` still resolves
- GTK 3/4 `settings.ini` and `environment.d/80-cursor.conf` so the pointer survives session restart
- Waybar-debug script for diagnostics
- Waybar-test script for waybar troubleshooting
- UNINSTALL.sh script for clean removal
- Comprehensive .gitignore file
- LICENSE file (MIT)
- CONTRIBUTING.md guidelines
- Screenshots directory structure
- CHANGELOG.md for tracking updates
- Screen recording toggle (`Mod+Print` via `record-toggle` script, SIGINT-finalized MP4)
- Waybar `custom/rec` indicator (pulses red while recording)
- Animated wallpaper (awww) visible in overview backdrop via `place-within-backdrop` layer-rule

### Changed
- Lock screen no longer shows the password length: a fixed run of scrambled symbols instead of one `*` per character
- Installer preflight: OS/kernel/niri version, required+optional deps, symlink conflicts, `--check`/`--yes`
- Alacritty David palette (blood-black bg, yellow/red chrome); Niri `xcursor-theme "Edgerunners"`
- Installer/uninstaller now link Kitty, cursor theme, GTK settings, and cursor env
- Installer now includes waybar-debug and waybar-test in required files
- Improved README with badges and better structure
- Added battery, network, bluetooth modules to waybar (temporarily simplified)
- Enhanced installer with better error handling and file verification
- Wallpaper stack: Quickshell draws the poster wallpaper (swaybg moon.png only if Quickshell is missing); `awww-daemon` + `awww img` shows animated-wave.gif on backdrop layer
- Waybar: transparent bar, every module its own floating pill
- Mako restyled (accent border, app-name tag) and `urgency=high` fixed to `critical`; swaylock config cleaned of swaylock-effects options and now linked by the installer

### Fixed
- Lock screen clears the field on `Enter` and keeps keys typed during PAM's ~2s fail delay, so a fast retry is no longer cut short; one failure is no longer counted twice
- niri binds, waybar modules and `.zshrc` no longer hardcode `/home/jt` (use `$HOME`)
- `wpctl` dependency now points at `wireplumber`
- Removed config.jsonc conflict in waybar config
- Fixed installer to handle all new scripts
- Corrected script permissions for waybar utilities

### Removed
- Extraneous waybar HTML file (accidental commit)

## [0.1.0] - 2025-01-10

### Added
- Initial release
- Niri window manager configuration
- Waybar status bar with cyberpunk theme
- Alacritty terminal with cyberpunk colors
- Fuzzel app launcher with neon styling
- Screenshot crop tool with auto-naming
- Power menu for lock/logout/shutdown
- Comprehensive installer script with options
- Hotkey overlay for keybinds reference
- Wallpaper support with swaybg
- Multiple waybar modules (workspaces, clock, system info)

### Features
- Column-based tiling layout
- Scrollable workspaces
- Cyberpunk color scheme throughout
- Transparency effects
- Custom keybinds
- Hotkey overlay (`Mod+Shift+/`)
- Window rules for opacity and decorations

### Documentation
- README with installation instructions
- DEPENDENCIES.md with package list
- NIRI_GUIDE.md with workspace management
- Troubleshooting section
