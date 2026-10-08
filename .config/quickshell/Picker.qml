import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: win

    visible: Rice.pickerOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-picker"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    readonly property var sel: Rice.walls[dial.currentIndex] ?? null
    readonly property color selAccent: sel ? sel.accent : Rice.accent

    onVisibleChanged: if (visible) dial.currentIndex = Math.max(0, Rice.walls.indexOf(Rice.current))

    function pick() {
        if (!sel) return;
        if (sel === Rice.current) Rice.pickerOpen = false;
        else Rice.apply(sel.file);
    }

    function cycleMode(n) {
        const m = Rice.modes;
        Rice.mode = m[(m.indexOf(Rice.mode) + n + m.length) % m.length];
    }

    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.35 }
    MouseArea { anchors.fill: parent; onClicked: Rice.pickerOpen = false }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            switch (e.key) {
            case Qt.Key_Left: case Qt.Key_Up: case Qt.Key_H: case Qt.Key_K:
                dial.decrementCurrentIndex(); break;
            case Qt.Key_Right: case Qt.Key_Down: case Qt.Key_L: case Qt.Key_J:
                dial.incrementCurrentIndex(); break;
            case Qt.Key_Tab: win.cycleMode(1); break;
            case Qt.Key_Backtab: win.cycleMode(-1); break;
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: win.pick(); break;
            case Qt.Key_Escape: Rice.pickerOpen = false; break;
            default: return;
            }
            e.accepted = true;
        }
    }

    Item {
        id: box
        width: 560; height: 560
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -50

        Rectangle {
            anchors.centerIn: parent
            width: 500; height: 500; radius: 250
            color: "#e60d0d11"
            border.color: "#2a2a33"; border.width: 3
            Rectangle {
                anchors.centerIn: parent
                width: 470; height: 470; radius: 235
                color: "transparent"
                border.color: Qt.rgba(win.selAccent.r, win.selAccent.g, win.selAccent.b, 0.35)
                border.width: 1
            }
        }

        MouseArea {
            anchors.fill: parent
            onWheel: w => w.angleDelta.y > 0 ? dial.decrementCurrentIndex() : dial.incrementCurrentIndex()
        }

        PathView {
            id: dial
            anchors.fill: parent
            model: Rice.walls
            pathItemCount: Math.min(6, Rice.walls.length)
            preferredHighlightBegin: 0
            preferredHighlightEnd: 0
            highlightRangeMode: PathView.StrictlyEnforceRange
            highlightMoveDuration: 260
            interactive: false

            path: Path {
                startX: 280; startY: 90
                PathArc { x: 280; y: 470; radiusX: 190; radiusY: 190 }
                PathArc { x: 280; y: 90; radiusX: 190; radiusY: 190 }
            }

            delegate: Item {
                id: slot
                required property var modelData
                required property int index
                readonly property bool active: PathView.isCurrentItem
                width: 112; height: 112
                z: active ? 2 : 1
                scale: active ? 1.22 : 1
                Behavior on scale { NumberAnimation { duration: 180 } }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "black"
                    border.width: slot.active ? 5 : 3
                    border.color: slot.active ? "white" : "#2a2a33"
                    Image {
                        anchors.fill: parent
                        source: Rice.url(slot.modelData)
                        sourceSize.width: 256
                        fillMode: Image.PreserveAspectCrop
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: -12
                    visible: !slot.active
                    text: slot.index + 1
                    font.family: Rice.pixel
                    font.pixelSize: 16
                    color: "white"
                    style: Text.Outline; styleColor: "black"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: slot.active ? win.pick() : dial.currentIndex = slot.index
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 200; height: 200; radius: 100
            color: "#0d0d11"
            border.color: "#3a3a44"; border.width: 6

            Rectangle {
                anchors.centerIn: parent
                width: 176; height: 176; radius: 88
                color: "transparent"
                border.color: win.selAccent; border.width: 2
            }

            Column {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 160
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: win.sel?.name ?? ""
                    font.family: Rice.pixel
                    font.pixelSize: 22
                    color: "white"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.sel?.tag ?? ""
                    font.family: Rice.pixel
                    font.pixelSize: 11
                    color: win.selAccent
                }
            }

            MouseArea { anchors.fill: parent; onClicked: win.pick() }
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "TRANSITION MODE"
            font.family: Rice.pixel
            font.pixelSize: 11
            color: "#c8c8c8"
        }

        Row {
            spacing: 10
            Repeater {
                model: Rice.modes
                delegate: Rectangle {
                    id: chip
                    required property string modelData
                    readonly property bool on: Rice.mode === modelData
                    width: label.implicitWidth + 30; height: 40; radius: 8
                    color: on ? win.selAccent : "#e60d0d11"
                    border.color: on ? win.selAccent : "#3a3a44"; border.width: 2
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: chip.modelData.toUpperCase()
                        font.family: Rice.pixel
                        font.pixelSize: 16
                        color: chip.on ? "#0d0d11" : "white"
                    }
                    MouseArea { anchors.fill: parent; onClicked: Rice.mode = chip.modelData }
                }
            }
        }
    }
}
