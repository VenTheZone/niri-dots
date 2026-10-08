import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "rice-wall"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "black"

    property real progress: 1
    property real revealAmt: Rice.reveal ? 1 : 0
    property real spot: torch.containsMouse ? 1 : 0
    property color accent: Rice.accent
    readonly property color shade: Qt.rgba(accent.r * 0.1, accent.g * 0.1, accent.b * 0.1, 1)

    Behavior on revealAmt { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }
    Behavior on spot { NumberAnimation { duration: 350 } }
    Behavior on accent { ColorAnimation { duration: 900 } }

    NumberAnimation on progress {
        id: swapAnim
        running: false
        from: 0; to: 1
        duration: 1100
        easing.type: Easing.InOutCubic
    }

    function swap() {
        if (Rice.current === cur.wall) return;
        prev.wall = cur.wall;
        cur.wall = Rice.current;
        swapAnim.restart();
    }

    Connections {
        target: Rice
        function onCurrentChanged() { win.swap(); }
    }
    Component.onCompleted: swap()

    component Poster: Item {
        property var wall: null
        anchors.fill: parent
        Image {
            anchors.fill: parent
            source: Rice.url(parent.wall)
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width, win.height)
        }
    }

    Poster { id: cur }
    Poster { id: prev }
    ShaderEffectSource { id: curTex; sourceItem: cur; hideSource: true }
    ShaderEffectSource { id: prevTex; sourceItem: prev; hideSource: true }

    ShaderEffect {
        anchors.fill: parent
        property var cur: curTex
        property var prev: prevTex
        property color accent: win.accent
        property color shade: win.shade
        property point mouse: Qt.point(torch.mouseX / width, torch.mouseY / height)
        property real aspect: width / height
        property real radius: 0.26
        property real spot: win.spot
        property real reveal: win.revealAmt
        property real progress: win.progress
        property real mode: Rice.transMode
        fragmentShader: Qt.resolvedUrl("shaders/wall.frag.qsb")
    }

    // Poster typography kept to the corners so faces stay clear:
    // faction ghosted top-right, “NAME” sinking into the bottom-left.
    Text {
        text: cur.wall?.tag ?? ""
        font.family: Rice.display
        font.pixelSize: win.height * 0.15
        color: Qt.tint(win.shade, Qt.rgba(win.accent.r, win.accent.g, win.accent.b, win.revealAmt))
        x: win.width * 1.03 - width
        y: -win.height * 0.03
        opacity: 0.5 * win.progress
    }

    Text {
        text: cur.wall ? "\u201C" + cur.wall.name + "\u201D" : ""
        font.family: Rice.display
        font.pixelSize: win.height * 0.18
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 24
        width: win.width * 0.62
        color: Qt.lighter(win.accent, 1.15)
        style: Text.Outline
        styleColor: Qt.rgba(win.shade.r, win.shade.g, win.shade.b, 0.5)
        x: win.width * 0.02
        y: win.height - contentHeight * 0.72
        opacity: win.progress
    }

    MouseArea {
        id: torch
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) Rice.pickerOpen = !Rice.pickerOpen;
            else Rice.reveal = !Rice.reveal;
        }
    }
}
