import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Picker {}
    Music {}
    Osd {}
    Lock {}
}
