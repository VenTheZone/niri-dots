import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris

PanelWindow {
    id: win

    property bool open: false
    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real frac: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0

    visible: open
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "rice-music"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "black"

    function time(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    IpcHandler {
        target: "music"
        function toggle(): void { win.open = !win.open; }
    }

    // Mpris only pushes position on seeks, so poll it while the player is on screen
    Timer {
        interval: 500
        repeat: true
        running: win.open && win.playing
        onTriggered: win.player.positionChanged()
    }

    ShaderEffect {
        anchors.fill: parent
        property color accent: Rice.accent
        property size res: Qt.size(width, height)
        property real spin: 0
        fragmentShader: Qt.resolvedUrl("shaders/halftone.frag.qsb")
        NumberAnimation on spin { from: 0; to: 6.2832; duration: 14000; loops: Animation.Infinite; running: win.open }
    }

    MouseArea { anchors.fill: parent; onClicked: win.open = false }

    Item {
        focus: true
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) win.open = false;
            else if (e.key === Qt.Key_Space) win.player?.togglePlaying();
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L) win.player?.next();
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) win.player?.previous();
            else return;
            e.accepted = true;
        }
    }

    // kaomoji doodles
    Repeater {
        model: [
            { t: "o3o", x: 0.29, y: 0.3, r: -12 },
            { t: "\u2022\u03C9\u2022", x: 0.62, y: 0.16, r: 8 },
            { t: "-\u03C9-", x: 0.8, y: 0.22, r: -4 },
            { t: "=^\uFF65\u03C9\uFF65^=", x: 0.47, y: 0.3, r: 6 },
            { t: "(\u00B4\uFF65_\uFF65`)", x: 0.86, y: 0.8, r: -8 }
        ]
        Text {
            required property var modelData
            x: win.width * modelData.x
            y: win.height * modelData.y
            rotation: modelData.r
            text: modelData.t
            font.family: Rice.pixel
            font.pixelSize: win.height * 0.03
            color: "white"
            opacity: 0.9
        }
    }

    // album art "vinyl"
    Item {
        id: disc
        width: win.height * 0.38; height: width
        x: win.width * 0.17 - width / 2
        y: win.height * 0.44 - height / 2

        Rectangle {
            anchors.fill: parent
            anchors.margins: -16
            radius: width / 2
            color: "black"
            border.color: Rice.accent; border.width: 5
        }
        ClippingRectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#16161c"
            Image {
                anchors.fill: parent
                source: win.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width, height)
            }
            Text {
                anchors.centerIn: parent
                visible: !win.player?.trackArtUrl
                text: "\u266A"
                font.pixelSize: parent.height * 0.4
                color: Rice.accent
            }
            RotationAnimation on rotation {
                from: 0; to: 360
                duration: 16000
                loops: Animation.Infinite
                running: win.open
                paused: running && !win.playing
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.09; height: width; radius: width / 2
            color: "black"
            border.color: Rice.accent; border.width: 3
        }
    }

    // title / artist tags
    Column {
        anchors.horizontalCenter: disc.horizontalCenter
        y: disc.y + disc.height + 40
        spacing: 10

        Repeater {
            model: [
                { t: win.player?.trackTitle || "NO SIGNAL", s: 0.026 },
                { t: win.player?.trackArtist || (win.player?.identity ?? "nothing playing"), s: 0.018 }
            ]
            Rectangle {
                required property var modelData
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(label.implicitWidth + 30, win.width * 0.3)
                height: label.implicitHeight + 12
                radius: 4
                color: "black"
                border.color: Rice.accent; border.width: 2
                Text {
                    id: label
                    anchors.centerIn: parent
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: parent.modelData.t
                    font.family: Rice.pixel
                    font.pixelSize: win.height * parent.modelData.s
                    color: "white"
                }
            }
        }
    }

    // zigzag progress
    Canvas {
        id: zig
        x: win.width * 0.5
        y: win.height * 0.47
        width: win.width * 0.4
        height: 40
        property real frac: win.frac
        property color accent: Rice.accent
        onFracChanged: requestPaint()
        onAccentChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const half = 9, amp = 9, mid = height / 2, split = width * frac;
            const yAt = x => {
                const k = Math.floor(x / half), t = (x - k * half) / half;
                const a = k % 2 ? amp : -amp;
                return mid + a + (-a - a) * t;
            };
            const stroke = (x0, x1, col) => {
                ctx.strokeStyle = col;
                ctx.beginPath();
                ctx.moveTo(x0, yAt(x0));
                for (let x = Math.ceil(x0 / half) * half; x < x1; x += half) ctx.lineTo(x, yAt(x));
                ctx.lineTo(x1, yAt(x1));
                ctx.stroke();
            };
            ctx.lineWidth = 4;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";
            stroke(12, Math.max(12, split), "white");
            stroke(Math.max(12, split), width - 12, accent);
            ctx.fillStyle = "white";
            for (const cx of [8, width - 8, Math.max(12, Math.min(width - 12, split))]) {
                ctx.beginPath();
                ctx.arc(cx, cx === 8 || cx === width - 8 ? mid : yAt(cx), cx === 8 || cx === width - 8 ? 6 : 9, 0, Math.PI * 2);
                ctx.fill();
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: m => { if (win.player?.canSeek) win.player.position = m.x / width * win.player.length; }
        }
    }

    Text {
        anchors.right: zig.right
        anchors.top: zig.bottom
        anchors.topMargin: 6
        text: win.player ? win.time(win.player.position) + " / " + win.time(win.player.length) : ""
        font.family: Rice.pixel
        font.pixelSize: win.height * 0.016
        color: "#c8c8c8"
    }

    // controls
    Row {
        anchors.horizontalCenter: zig.horizontalCenter
        y: win.height * 0.6
        spacing: win.width * 0.05

        Repeater {
            model: [
                { glyph: "\u{f04ae}", big: false, act: () => win.player?.previous() },
                { glyph: win.playing ? "\u{f03e4}" : "\u{f040a}", big: true, act: () => win.player?.togglePlaying() },
                { glyph: "\u{f04ad}", big: false, act: () => win.player?.next() }
            ]
            Rectangle {
                id: btn
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                width: win.height * (modelData.big ? 0.11 : 0.08); height: width
                radius: width * 0.22
                rotation: -6
                color: modelData.big ? Rice.accent : "black"
                border.color: modelData.big ? "black" : Rice.accent; border.width: 4
                scale: hover.containsMouse ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: btn.modelData.glyph
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: parent.height * 0.5
                    color: btn.modelData.big ? "black" : Rice.accent
                }
                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: btn.modelData.act()
                }
            }
        }
    }

    Text {
        anchors.horizontalCenter: zig.horizontalCenter
        y: win.height * 0.9
        text: "SPACE play  \u2190 \u2192 skip  ESC close"
        font.family: Rice.pixel
        font.pixelSize: win.height * 0.014
        color: "#8a8a82"
    }
}
