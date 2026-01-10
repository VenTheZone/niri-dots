# Niri Workspace and Window Movement Guide

## How Niri Works

### Hierarchy: Workspace → Column → Window

```
Workspace 1          Workspace 2
┌─────────────┐      ┌─────────────┐
│ [Column 1] │      │ [Column 1] │
│  Window A   │      │  Window X   │
│  Window B   │      │  Window Y   │
│             │      │             │
│ [Column 2] │      │ [Column 2] │
│  Window C   │      │  Window Z   │
└─────────────┘      └─────────────┘
```

### Key Concepts

- **Workspace**: Virtual desktop (1, 2, 3, 4, 5)
- **Column**: Vertical stack of windows (tiled)
- **Window**: Individual application

### Default Movement Commands

| Type | Action | Description |
|-------|---------|-------------|
| **Focus Column** | `focus-column-left` | Move focus left in workspace |
| | `focus-column-right` | Move focus right in workspace |
| **Focus Window** | `focus-window-up` | Focus window above in column |
| | `focus-window-down` | Focus window below in column |
| **Move Column** | `move-column-left` | Move entire column left |
| | `move-column-right` | Move entire column right |
| **Move Window** | `move-window-up` | Move window up within column |
| | `move-window-down` | Move window down within column |
| **Workspace** | `move-column-to-workspace-up` | Move column to prev workspace |
| | `move-column-to-workspace-down` | Move column to next workspace |

## Recommended Keybinds

### Within Workspace (Position)

| Key | Action | Purpose |
|-----|--------|---------|
| `Mod+Shift+Left` | Move column **left** (reposition within workspace) |
| `Mod+Shift+Right` | Move column **right** (reposition within workspace) |
| `Mod+Shift+Up` | Move column to **previous workspace** |
| `Mod+Shift+Down` | Move column to **next workspace** |

**Usage:**
1. Use `Mod+Shift+Left/Right` to arrange columns in workspace
2. Use `Mod+Shift+Up/Down` to move columns between workspaces
3. Follow with `Mod+1-5` to see where you moved it
