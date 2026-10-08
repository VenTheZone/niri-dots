import QtQuick
import QtQuick.Effects
import QtMultimedia
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pam

Scope {
    id: root

    property string pass: ""
    property bool failed: false
    property bool busy: false
    property bool unlocking: false

    function lock() {
        pass = "";
        failed = false;
        busy = false;
        unlocking = false;
        persist.locked = true;
    }

    PersistentProperties {
        id: persist
        reloadableId: "lock"
        property bool locked: false
    }

    // a hot-reload while locked makes the new WlSessionLock collide with the old one
    // ("Output is already locked") and kills the shell, so no reloads until unlocked
    Binding {
        target: Quickshell
        property: "watchFiles"
        value: !persist.locked
    }

    function submit() {
        if (busy || unlocking || pass === "") return;
        busy = true;
        failed = false;
        pam.start();
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(); }
        // check before `qs kill`: killing the shell while locked leaves niri with a dead lock
        function isLocked(): bool { return persist.locked; }
    }

    PamContext {
        id: pam
        onPamMessage: {
            if (responseRequired) respond(root.pass);
        }
        onCompleted: result => {
            root.busy = false;
            if (result === PamResult.Success) {
                root.unlocking = true;
            } else {
                root.pass = "";
                root.failed = true;
            }
        }
        onError: {
            root.busy = false;
            root.pass = "";
            root.failed = true;
        }
    }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // TV channels: any video/gif/image dropped in wallpaper/tv, posters if it's empty
    FolderListModel {
        id: tvFiles
        folder: "file://" + Quickshell.env("HOME") + "/.config/niri/wallpaper/tv"
        nameFilters: ["*.mp4", "*.webm", "*.mkv", "*.mov", "*.gif", "*.webp", "*.png", "*.jpg", "*.jpeg"]
        showDirs: false
    }

    WlSessionLock {
        id: sl
        locked: persist.locked

        WlSessionLockSurface {
            id: surf
            color: "#050507"

            readonly property real tvW: Math.min(width * 0.5, height * 0.85)
            readonly property real tvH: tvW * 0.64
            readonly property var walls: Rice.walls
            readonly property int chCount: tvFiles.count || walls.length
            property int ch: Math.floor(Math.random() * 1000)
            property int dir: 1
            readonly property int chIdx: chCount ? ((ch % chCount) + chCount) % chCount : 0
            readonly property var chWall: tvFiles.count ? null : walls[chIdx] ?? null
            readonly property string chUrl: tvFiles.count ? String(tvFiles.get(chIdx, "fileUrl")) : Rice.url(chWall)
            readonly property string chKind: /\.(mp4|webm|mkv|mov)$/i.test(chUrl) ? "video"
                : /\.(gif|webp)$/i.test(chUrl) ? "anim" : "image"
            property real power: 0

            function flip(d) {
                dir = d;
                flick.restart();
                chTimer.restart();
            }

            NumberAnimation on power { from: 0; to: 1; duration: 750; easing.type: Easing.OutCubic }

            Item {
                id: scene
                anchors.fill: parent
                property real zoom: 1

                transform: Scale {
                    origin.x: tv.x + bezel.x + bezel.width / 2
                    origin.y: tv.y + bezel.y + bezel.height / 2
                    xScale: scene.zoom
                    yScale: scene.zoom
                }

                // the room: blurred current poster, dimmed
                Image {
                    id: room
                    anchors.fill: parent
                    source: Rice.url(Rice.current)
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(width / 4, height / 4)
                    visible: false
                }
                MultiEffect {
                    anchors.fill: room
                    source: room
                    blurEnabled: true
                    blur: 1
                    blurMax: 48
                    brightness: -0.62
                    saturation: -0.4
                }

                // light spill from the screen
                Rectangle {
                    id: spill
                    anchors.centerIn: tv
                    width: surf.tvW * 1.25; height: surf.tvH * 1.1
                    radius: height / 2
                    color: surf.chWall ? surf.chWall.accent : Rice.accent
                    visible: false
                }
                MultiEffect {
                    anchors.fill: spill
                    source: spill
                    autoPaddingEnabled: true
                    blurEnabled: true
                    blur: 1
                    blurMax: 120
                    opacity: 0.16
                }

                // table
                Rectangle {
                    x: 0; width: parent.width
                    y: vcr.y + vcr.height
                    height: parent.height - y
                    color: "#0b0908"
                    Rectangle { width: parent.width; height: 2; color: "#2e241e" }
                }

                // rabbit ears
                Repeater {
                    model: [-28, 24]
                    Rectangle {
                        required property int modelData
                        x: tv.x + tv.width * 0.42 - width / 2
                        y: tv.y - height + 6
                        width: 3; height: surf.tvH * 0.38
                        color: "#9a9a9a"
                        antialiasing: true
                        transformOrigin: Item.Bottom
                        rotation: modelData
                    }
                }
                Rectangle {
                    x: tv.x + tv.width * 0.42 - width / 2
                    y: tv.y - height / 2
                    width: 54; height: 24; radius: 12
                    color: "#1a1513"
                }

                Rectangle {
                    id: tv
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -surf.height * 0.05
                    width: surf.tvW; height: surf.tvH
                    radius: width * 0.03
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#3b302a" }
                        GradientStop { position: 1; color: "#1a1513" }
                    }
                    border.color: "#4c3e35"; border.width: 2
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "black"
                        shadowBlur: 1
                        shadowVerticalOffset: 24
                    }

                    Rectangle {
                        id: bezel
                        x: tv.width * 0.045; y: tv.height * 0.07
                        width: tv.width * 0.7; height: tv.height * 0.86
                        radius: tv.width * 0.035
                        color: "#0d0b0a"
                        border.color: "#000"; border.width: 3

                        ClippingRectangle {
                            id: glass
                            anchors.fill: parent
                            anchors.margins: tv.width * 0.022
                            radius: tv.width * 0.06
                            color: "black"

                            Item {
                                id: tube
                                anchors.fill: parent
                                transform: Scale {
                                    origin.x: tube.width / 2
                                    origin.y: tube.height / 2
                                    xScale: Math.min(1, surf.power * 2.5)
                                    yScale: surf.power < 0.4 ? 0.006 : (surf.power - 0.4) / 0.6
                                }

                                Item {
                                    id: channel
                                    anchors.fill: parent
                                    Loader {
                                        anchors.fill: parent
                                        sourceComponent: surf.chKind === "video" ? videoChannel
                                            : surf.chKind === "anim" ? animChannel : imageChannel
                                    }
                                    Component {
                                        id: videoChannel
                                        Item {
                                            VideoOutput {
                                                id: vo
                                                anchors.fill: parent
                                                fillMode: VideoOutput.PreserveAspectCrop
                                            }
                                            // no audioOutput: the lock screen stays silent
                                            MediaPlayer {
                                                source: surf.chUrl
                                                videoOutput: vo
                                                loops: MediaPlayer.Infinite
                                                onSourceChanged: play()
                                                Component.onCompleted: play()
                                            }
                                        }
                                    }
                                    Component {
                                        id: animChannel
                                        AnimatedImage {
                                            source: surf.chUrl
                                            fillMode: Image.PreserveAspectCrop
                                        }
                                    }
                                    Component {
                                        id: imageChannel
                                        Image {
                                            source: surf.chUrl
                                            fillMode: Image.PreserveAspectCrop
                                            sourceSize: Qt.size(width, height)
                                        }
                                    }
                                    Text {
                                        id: chLabel
                                        x: parent.width * 0.08; y: parent.height * 0.92 - height
                                        text: "CH " + String(surf.chIdx + 1).padStart(2, "0")
                                        font.family: Rice.pixel
                                        font.pixelSize: parent.height * 0.07
                                        color: "#7cff6b"
                                        style: Text.Outline; styleColor: "black"
                                        opacity: 0
                                        SequentialAnimation on opacity {
                                            id: chFlash
                                            running: false
                                            PropertyAction { value: 1 }
                                            PauseAnimation { duration: 1800 }
                                            NumberAnimation { to: 0; duration: 300 }
                                        }
                                    }
                                }
                                ShaderEffectSource { id: channelTex; sourceItem: channel; hideSource: true }

                                ShaderEffect {
                                    id: crt
                                    anchors.fill: parent
                                    property var src: channelTex
                                    property real time: 0
                                    property real noise: 1
                                    fragmentShader: Qt.resolvedUrl("shaders/crt.frag.qsb")
                                    NumberAnimation on time { from: 0; to: 10000; duration: 10000000; loops: Animation.Infinite }
                                    NumberAnimation on noise { from: 1; to: 0; duration: 900; easing.type: Easing.OutQuad }
                                }

                                SequentialAnimation {
                                    id: flick
                                    NumberAnimation { target: crt; property: "noise"; to: 1; duration: 110 }
                                    ScriptAction { script: { surf.ch += surf.dir; chFlash.restart(); } }
                                    PauseAnimation { duration: 90 }
                                    NumberAnimation { target: crt; property: "noise"; to: 0; duration: 420; easing.type: Easing.OutQuad }
                                }
                                Timer {
                                    id: chTimer
                                    interval: 9000
                                    repeat: true
                                    running: surf.chCount > 1 && !root.unlocking
                                    onTriggered: surf.flip(1)
                                }

                                // clock and prompt sit on the glass, not warped by it
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: parent.height * 0.1
                                    spacing: 2

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 6
                                        readonly property var parts: Qt.formatDateTime(clock.date, "hh:mm AP").split(" ")
                                        Text {
                                            id: hm
                                            text: parent.parts[0]
                                            font.family: Rice.pixel
                                            font.pixelSize: glass.height * 0.17
                                            color: "white"
                                            style: Text.Outline; styleColor: "black"
                                        }
                                        Text {
                                            anchors.baseline: hm.baseline
                                            text: Qt.formatDateTime(clock.date, "ss")
                                            font.family: Rice.pixel
                                            font.pixelSize: glass.height * 0.07
                                            color: Rice.accent
                                            style: Text.Outline; styleColor: "black"
                                        }
                                        Text {
                                            anchors.baseline: hm.baseline
                                            text: parent.parts[1]
                                            font.family: Rice.pixel
                                            font.pixelSize: glass.height * 0.07
                                            color: "white"
                                            style: Text.Outline; styleColor: "black"
                                        }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Qt.formatDateTime(clock.date, "dddd  dd MMMM yyyy").toUpperCase()
                                        font.family: Rice.pixel
                                        font.pixelSize: glass.height * 0.04
                                        color: "white"
                                        style: Text.Outline; styleColor: "black"
                                    }
                                }

                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: parent.height * 0.14
                                    spacing: 12

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.busy ? "Verifying..." : "Enter password"
                                        font.family: Rice.pixel
                                        font.pixelSize: 20
                                        color: "white"
                                        style: Text.Outline; styleColor: "black"
                                    }

                                    Rectangle {
                                        id: field
                                        width: glass.width * 0.46; height: 42
                                        radius: height / 2
                                        color: "#e6000000"
                                        border.width: 2
                                        border.color: root.failed ? "#ff003c" : (input.activeFocus ? "white" : "#666")
                                        transform: Translate { id: shake }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 18
                                            anchors.right: dot.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            clip: true
                                            text: "*".repeat(root.pass.length) + (caret.on ? "_" : " ")
                                            font.family: Rice.pixel
                                            font.pixelSize: 18
                                            color: "white"
                                        }
                                        Rectangle {
                                            id: dot
                                            anchors.right: parent.right
                                            anchors.rightMargin: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 8; height: 8; radius: 4
                                            color: root.failed ? "#ff003c" : "white"
                                        }
                                        Timer {
                                            id: caret
                                            property bool on: true
                                            interval: 530; repeat: true; running: true
                                            onTriggered: on = !on
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "ACCESS DENIED"
                                        visible: root.failed
                                        font.family: Rice.pixel
                                        font.pixelSize: 14
                                        color: "#ff003c"
                                        style: Text.Outline; styleColor: "black"
                                    }
                                }

                                SequentialAnimation {
                                    id: shakeAnim
                                    NumberAnimation { target: shake; property: "x"; to: -14; duration: 50 }
                                    NumberAnimation { target: shake; property: "x"; to: 12; duration: 70 }
                                    NumberAnimation { target: shake; property: "x"; to: -8; duration: 60 }
                                    NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "white"
                                    opacity: surf.power < 0.5 ? 1 : (1 - surf.power) * 2
                                }
                            }

                            // glass glare
                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0; color: "#14ffffff" }
                                    GradientStop { position: 0.35; color: "#00ffffff" }
                                }
                            }
                        }
                    }

                    // control panel
                    Column {
                        anchors.left: bezel.right
                        anchors.right: parent.right
                        anchors.top: bezel.top
                        anchors.topMargin: tv.height * 0.04
                        spacing: tv.height * 0.05

                        Repeater {
                            model: [35, -60]
                            Rectangle {
                                required property int modelData
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: tv.width * 0.11; height: width; radius: width / 2
                                color: "#141110"
                                border.color: "#5e4e43"; border.width: 3
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 4; height: parent.height * 0.62
                                    radius: 2
                                    color: "#8a7a6e"
                                    rotation: parent.modelData
                                }
                            }
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: tv.height * 0.018
                            Repeater {
                                model: 9
                                Rectangle {
                                    width: tv.width * 0.13; height: 3; radius: 1.5
                                    color: "#0c0a09"
                                }
                            }
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 10; height: 10; radius: 5
                            color: root.failed ? "#ff003c" : "#7cff6b"
                        }
                    }
                }

                // VCR deck showing the channel
                Rectangle {
                    id: vcr
                    anchors.horizontalCenter: tv.horizontalCenter
                    y: tv.y + tv.height + 10
                    width: tv.width * 0.94; height: tv.height * 0.13
                    radius: 6
                    color: "#131113"
                    border.color: "#2b2628"; border.width: 2

                    Rectangle {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -parent.width * 0.08
                        width: parent.width * 0.42; height: parent.height * 0.22
                        radius: 3
                        color: "#060506"
                        border.color: "#2b2628"
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: parent.width * 0.04
                        anchors.verticalCenter: parent.verticalCenter
                        width: deckText.implicitWidth + 24; height: parent.height * 0.5
                        radius: 4
                        color: "#060506"
                        Text {
                            id: deckText
                            anchors.centerIn: parent
                            text: "CH " + String(surf.chIdx + 1).padStart(2, "0") + "/" + surf.chCount
                                + (surf.chKind === "image" ? "  STILL" : "  PLAY")
                            font.family: Rice.pixel
                            font.pixelSize: vcr.height * 0.26
                            color: Rice.accent
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: parent.width * 0.04
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u25B6"
                        font.pixelSize: vcr.height * 0.32
                        color: "#8a8a8a"
                    }
                }
            }

            Rectangle {
                id: blackout
                anchors.fill: parent
                color: "black"
                opacity: 0
            }

            SequentialAnimation {
                running: root.unlocking
                ParallelAnimation {
                    NumberAnimation { target: scene; property: "zoom"; to: 3.4; duration: 750; easing.type: Easing.InCubic }
                    NumberAnimation { target: blackout; property: "opacity"; to: 1; duration: 750; easing.type: Easing.InQuart }
                }
                ScriptAction { script: persist.locked = false }
            }

            Connections {
                target: root
                function onFailedChanged() { if (root.failed) shakeAnim.restart(); }
                function onPassChanged() { if (input.text !== root.pass) input.text = root.pass; }
            }

            TextInput {
                id: input
                opacity: 0
                focus: true
                echoMode: TextInput.Password
                onTextChanged: {
                    root.pass = text;
                    if (text !== "") root.failed = false;
                }
                Keys.onReturnPressed: root.submit()
                Keys.onEnterPressed: root.submit()
                Keys.onEscapePressed: root.pass = ""
                Keys.onUpPressed: surf.flip(1)
                Keys.onDownPressed: surf.flip(-1)
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
