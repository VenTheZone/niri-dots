import QtQuick
import QtQuick.Effects
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
    property int attempts: 0
    // fixed-length gibberish instead of one * per char, so the length never shows
    property string mask: ""
    // what PAM is checking; the field is cleared on submit so a retry can start right away
    property string attempt: ""
    // PAM's own explanation (e.g. faillock lockout), shown instead of the generic error
    property string pamMsg: ""
    onPassChanged: scramble()
    onBusyChanged: scramble()

    function scramble() {
        const g = "#$%&@*+=?/<>01";
        mask = pass === "" && !busy ? "" : Array.from({ length: 10 }, () => g[Math.floor(Math.random() * g.length)]).join("");
    }

    function lock() {
        pass = "";
        attempt = "";
        pamMsg = "";
        failed = false;
        attempts = 0;
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
        attempt = pass;
        pass = "";
        pamMsg = "";
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
            if (responseRequired) respond(root.attempt);
            else root.pamMsg = (root.pamMsg + " " + message).trim();
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.attempt = "";
                root.busy = false;
                root.unlocking = true;
            } else root.fail();
        }
        onError: root.fail()
    }

    // PAM can fire both error and completed for one failure; the busy guard counts it once.
    // pass only holds keys typed during the check, so it's kept for the retry
    function fail() {
        if (!busy) return;
        attempt = "";
        busy = false;
        attempts++;
        failed = true;
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
            // everything the TV and the HUD both animate lives here, so both copies stay in sync
            property real noise: 1
            property real shake: 0
            property real errShow: 0
            property real strobe: 0
            property int hackLines: 0
            property real hackProgress: 0
            property bool granted: false
            property bool blink: true
            readonly property string failText: root.pamMsg ? root.pamMsg.toUpperCase()
                : "BLACK ICE // AUTH FAILURE " + String(root.attempts).padStart(2, "0")

            // 0 = Neon Room (the TV), 1 = Netrunner HUD (full screen); random per lock, swaps every 30s
            property int look: Math.random() < 0.5 ? 0 : 1
            property real hudShow: look

            NumberAnimation on noise { from: 1; to: 0; duration: 900; easing.type: Easing.OutQuad }
            Timer { interval: 530; repeat: true; running: true; onTriggered: surf.blink = !surf.blink }

            Timer {
                interval: 30000; repeat: true
                running: !root.unlocking
                onTriggered: (surf.look ? toRoom : toHud).restart()
            }
            // dive into the TV screen and come out as the HUD
            SequentialAnimation {
                id: toHud
                ParallelAnimation {
                    NumberAnimation { target: scene; property: "zoom"; to: 3.4; duration: 650; easing.type: Easing.InCubic }
                    NumberAnimation { target: surf; property: "noise"; to: 0.6; duration: 650; easing.type: Easing.InQuad }
                }
                PropertyAction { target: tear; property: "visible"; value: true }
                PropertyAction { target: surf; property: "look"; value: 1 }
                NumberAnimation { target: surf; property: "hudShow"; to: 1; duration: 200 }
                PropertyAction { target: scene; property: "zoom"; value: 1 }
                PauseAnimation { duration: 150 }
                PropertyAction { target: tear; property: "visible"; value: false }
                NumberAnimation { target: surf; property: "noise"; to: 0; duration: 400; easing.type: Easing.OutQuad }
            }
            // drop out of the HUD back through the screen and pull out to the room
            SequentialAnimation {
                id: toRoom
                PropertyAction { target: tear; property: "visible"; value: true }
                NumberAnimation { target: surf; property: "noise"; to: 0.6; duration: 120 }
                PropertyAction { target: scene; property: "zoom"; value: 3.4 }
                PropertyAction { target: surf; property: "look"; value: 0 }
                NumberAnimation { target: surf; property: "hudShow"; to: 0; duration: 200 }
                PropertyAction { target: tear; property: "visible"; value: false }
                ParallelAnimation {
                    NumberAnimation { target: scene; property: "zoom"; to: 1; duration: 750; easing.type: Easing.OutCubic }
                    NumberAnimation { target: surf; property: "noise"; to: 0; duration: 750; easing.type: Easing.OutQuad }
                }
            }

            function flip(d) {
                dir = d;
                flick.restart();
                chTimer.restart();
            }

            NumberAnimation on power { from: 0; to: 1; duration: 750; easing.type: Easing.OutCubic }

            Item {
                id: scene
                anchors.fill: parent
                visible: surf.hudShow < 1
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

                LockRoom { anchors.fill: parent }

                // light spill from the screen
                Rectangle {
                    id: spill
                    anchors.centerIn: tv
                    width: surf.tvW * 1.25; height: surf.tvH * 1.1
                    radius: height / 2
                    color: surf.errShow > 0 ? "#ff003c" : root.unlocking ? "#7cff6b"
                        : surf.chWall ? surf.chWall.accent : Rice.accent
                    visible: false
                }
                MultiEffect {
                    anchors.fill: spill
                    source: spill
                    autoPaddingEnabled: true
                    blurEnabled: true
                    blur: 1
                    blurMax: 120
                    opacity: 0.26
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
                    transform: Translate { x: surf.shake }
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
                                    LockChannel {
                                        anchors.fill: parent
                                        url: surf.chUrl
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

                                    // inside the channel so the CRT shader tears it up
                                    LockAlerts {
                                        anchors.fill: parent
                                        view: surf
                                        hacking: root.unlocking
                                        failText: surf.failText
                                    }
                                }
                                ShaderEffectSource { id: channelTex; sourceItem: channel; hideSource: true }

                                ShaderEffect {
                                    id: crt
                                    anchors.fill: parent
                                    property var src: channelTex
                                    property real time: 0
                                    property real noise: surf.noise
                                    fragmentShader: Qt.resolvedUrl("shaders/crt.frag.qsb")
                                    NumberAnimation on time { from: 0; to: 10000; duration: 10000000; loops: Animation.Infinite }
                                }

                                SequentialAnimation {
                                    id: flick
                                    NumberAnimation { target: surf; property: "noise"; to: 1; duration: 110 }
                                    ScriptAction { script: { surf.ch += surf.dir; chFlash.restart(); } }
                                    PauseAnimation { duration: 90 }
                                    NumberAnimation { target: surf; property: "noise"; to: 0; duration: 420; easing.type: Easing.OutQuad }
                                }
                                Timer {
                                    id: chTimer
                                    interval: 9000
                                    repeat: true
                                    running: surf.chCount > 1 && !root.unlocking && surf.errShow === 0
                                    onTriggered: surf.flip(1)
                                }

                                // clock and prompt sit on the glass, not warped by it
                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: parent.height * 0.1
                                    spacing: 2
                                    visible: surf.errShow === 0 && !root.unlocking

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
                                    visible: surf.errShow === 0 && !root.unlocking

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.busy ? "DECRYPTING..." : "ENTER PASSWORD"
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

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 18
                                            anchors.right: dot.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            clip: true
                                            text: root.mask + (surf.blink && !root.busy ? "_" : " ")
                                            font.family: Rice.pixel
                                            font.pixelSize: 18
                                            color: root.busy ? Rice.accent : "white"
                                        }
                                        // keep the gibberish churning while PAM thinks
                                        Timer {
                                            interval: 60; repeat: true
                                            running: root.busy
                                            onTriggered: root.scramble()
                                        }
                                        Rectangle {
                                            id: dot
                                            anchors.right: parent.right
                                            anchors.rightMargin: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 8; height: 8; radius: 4
                                            color: root.failed ? "#ff003c" : "white"
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: glass.width * 0.8
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        text: root.pamMsg ? root.pamMsg.toUpperCase()
                                            : "ACCESS DENIED  //  ATTEMPT " + String(root.attempts).padStart(2, "0")
                                        visible: root.failed
                                        font.family: Rice.pixel
                                        font.pixelSize: 14
                                        color: "#ff003c"
                                        style: Text.Outline; styleColor: "black"
                                    }
                                }

                                SequentialAnimation {
                                    id: errAnim
                                    PropertyAction { target: surf; property: "errShow"; value: 1 }
                                    ParallelAnimation {
                                        SequentialAnimation {
                                            loops: 3
                                            PropertyAction { target: surf; property: "strobe"; value: 0.9 }
                                            PauseAnimation { duration: 60 }
                                            PropertyAction { target: surf; property: "strobe"; value: 0 }
                                            PauseAnimation { duration: 90 }
                                        }
                                        // signal tearing via the CRT shader
                                        SequentialAnimation {
                                            loops: 4
                                            NumberAnimation { target: surf; property: "noise"; to: 0.55; duration: 40 }
                                            NumberAnimation { target: surf; property: "noise"; to: 0.05; duration: 230 }
                                        }
                                        SequentialAnimation {
                                            NumberAnimation { target: surf; property: "shake"; to: -16; duration: 40 }
                                            NumberAnimation { target: surf; property: "shake"; to: 14; duration: 60 }
                                            NumberAnimation { target: surf; property: "shake"; to: -9; duration: 60 }
                                            NumberAnimation { target: surf; property: "shake"; to: 5; duration: 60 }
                                            NumberAnimation { target: surf; property: "shake"; to: 0; duration: 60 }
                                        }
                                    }
                                    PauseAnimation { duration: 700 }
                                    ParallelAnimation {
                                        NumberAnimation { target: surf; property: "errShow"; to: 0; duration: 200 }
                                        NumberAnimation { target: surf; property: "noise"; to: 0; duration: 200 }
                                    }
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

            LockHud {
                anchors.fill: parent
                view: surf
                lock: root
                date: clock.date
                opacity: surf.hudShow
                visible: opacity > 0
            }

            // look-swap glitch: torn colour bars that jump around
            Item {
                id: tear
                anchors.fill: parent
                visible: false
                Repeater {
                    id: bars
                    model: 8
                    Rectangle {
                        required property int index
                        color: ["#00f0ff", "#ff2a9d", "white", Rice.accent][index % 4]
                        opacity: 0.35
                    }
                }
                Timer {
                    interval: 40; repeat: true; triggeredOnStart: true
                    running: tear.visible
                    onTriggered: {
                        for (let i = 0; i < bars.count; i++) {
                            const b = bars.itemAt(i);
                            b.height = surf.height * (0.005 + Math.random() * 0.05);
                            b.y = Math.random() * surf.height;
                            b.width = surf.width * (0.3 + Math.random() * 0.7);
                            b.x = Math.random() * (surf.width - b.width);
                        }
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
                // run the breach, flash ACCESS GRANTED, then switch the set off like an old CRT
                ParallelAnimation {
                    NumberAnimation { target: surf; property: "hackLines"; from: 0; to: 5; duration: 900 }
                    NumberAnimation { target: surf; property: "hackProgress"; from: 0; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: surf; property: "noise"; from: 0.5; to: 0; duration: 350; easing.type: Easing.OutQuad }
                }
                PropertyAction { target: surf; property: "granted"; value: true }
                NumberAnimation { target: surf; property: "noise"; from: 0.6; to: 0; duration: 350; easing.type: Easing.OutQuad }
                PauseAnimation { duration: 500 }
                NumberAnimation { target: surf; property: "power"; to: 0; duration: 480; easing.type: Easing.InCubic }
                PauseAnimation { duration: 120 }
                ParallelAnimation {
                    NumberAnimation { target: scene; property: "zoom"; to: 3.4; duration: 650; easing.type: Easing.InCubic }
                    NumberAnimation { target: blackout; property: "opacity"; to: 1; duration: 650; easing.type: Easing.InQuart }
                }
                ScriptAction { script: persist.locked = false }
            }

            Connections {
                target: root
                function onFailedChanged() { if (root.failed) errAnim.restart(); }
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
