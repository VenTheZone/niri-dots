# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Waybar-debug script for diagnostics
- Waybar-test script for waybar troubleshooting
- UNINSTALL.sh script for clean removal
- Comprehensive .gitignore file
- LICENSE file (MIT)
- CONTRIBUTING.md guidelines
- Screenshots directory structure
- CHANGELOG.md for tracking updates

### Changed
- Installer now includes waybar-debug and waybar-test in required files
- Improved README with badges and better structure
- Added battery, network, bluetooth modules to waybar (temporarily simplified)
- Enhanced installer with better error handling and file verification

### Fixed
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
