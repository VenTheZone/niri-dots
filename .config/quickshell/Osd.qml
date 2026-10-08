import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: win

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    property bool shown: false
    property bool armed: false

    visible: shown || pill.opacity > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-osd"
    exclusionMode: ExclusionMode.Ignore
    anchors.left: true
    margins.left: 14
    implicitWidth: 40
    implicitHeight: 260
    color: "transparent"

    PwObjectTracker { objects: [win.sink] }

    // skip the burst of changes while pipewire binds the sink at startup
    Timer { interval: 2000; running: true; onTriggered: win.armed = true }
    Timer { id: hide; interval: 1400; onTriggered: win.shown = false }

    function poke() {
        if (!armed) return;
        shown = true;
        hide.restart();
    }
    onVolChanged: poke()
    onMutedChanged: poke()

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: width / 2
        color: "#0d0d11"
        border.color: "#2a2a33"; border.width: 2
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: icon.top
            anchors.bottomMargin: 8
            width: parent.width - 14
            height: (parent.height - 54) * Math.min(win.vol, 1)
            radius: width / 2
            color: win.muted ? "#55555f" : "white"
            Behavior on height { NumberAnimation { duration: 120 } }
        }

        Text {
            id: icon
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            text: win.muted ? "\u{f0581}" : "\u{f057e}"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color: win.muted ? "#ff003c" : "white"
        }
    }
}
