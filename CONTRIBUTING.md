# Contributing to Niri Dots

Thank you for your interest in contributing! Here are some guidelines to help you get started.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates.

When creating a bug report, include:
- **Description**: What happened and what you expected to happen
- **Steps to reproduce**: Clear steps to reproduce the issue
- **Environment**: Your distro, Niri version, and relevant package versions
- **Config**: Relevant configuration snippets (sanitized if needed)
- **Logs**: Error messages or logs from relevant components

### Suggesting Features

Feature suggestions are welcome! When suggesting a feature:
- Explain the use case clearly
- Consider if it benefits the general user base
- If it's a configuration option, provide examples
- Discuss implementation complexity

### Submitting Changes

#### Setup

1. Fork the repository
2. Create a branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-fix-name
   ```
3. Make your changes

#### Guidelines

- **Code Style**: Follow the existing style in the project
- **Scripts**: Use bash for scripts with clear comments
- **Configs**: Maintain consistent formatting and structure
- **Documentation**: Update relevant documentation (README, guides, etc.)

#### Testing

Before submitting:
- Test scripts for syntax errors: `bash -n script.sh`
- Verify JSON configs are valid
- Test the installer in dry-run mode
- Test on a clean system if possible

#### Commit Messages

Use clear, descriptive commit messages:
```
Add: New feature description
Fix: Bug fix description
Update: Update for new version
Docs: Documentation improvement
```

#### Pull Requests

1. Push your changes to your fork
2. Create a pull request with a clear title and description
3. Reference any related issues in the description
4. Wait for review and address feedback

## Project Structure

```
niri-dots/
├── .config/           # Configuration files
│   ├── niri/          # Niri WM config
│   ├── waybar/        # Waybar config and styles
│   ├── alacritty/     # Terminal config
│   └── fuzzel/        # App launcher config
├── .local/bin/         # Scripts and utilities
├── .zshrc             # Shell configuration
├── install.sh          # Installation script
├── UNINSTALL.sh       # Uninstallation script
├── README.md          # Main documentation
├── DEPENDENCIES.md    # Dependencies list
└── NIRI_GUIDE.md     # Niri usage guide
```

## Areas for Contribution

### Documentation
- Improve README clarity
- Add more troubleshooting steps
- Translate documentation to other languages
- Create video tutorials

### Features
- Add new waybar modules
- Create additional color themes
- Add more utility scripts
- Support additional distributions

### Testing
- Test on different Linux distributions
- Test on different hardware
- Report compatibility issues

## Getting Help

- Join discussions for questions
- Check existing issues before creating new ones
- Be respectful and constructive in all interactions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
