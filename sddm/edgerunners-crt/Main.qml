// Login screen twin of .config/quickshell/Lock.qml, in plain QtQuick (no Quickshell in the greeter).
// install.sh copies fonts/, crt.frag.qsb, tv/ and room.jpg next to this file.
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Qt.labs.folderlistmodel

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#050507"

    readonly property color accent: config.Accent || "#f3e600"
    readonly property real tvW: Math.min(width * 0.5, height * 0.85)
    readonly property real tvH: tvW * 0.64

    property int userIdx: 0
    property int sessionIdx: sessionModel.lastIndex
    property bool failed: false
    property bool busy: false
    property bool entering: false
    property int ch: Math.floor(Math.random() * 1000)
    property int dir: 1
    readonly property int chCount: tvFiles.count
    readonly property int chIdx: chCount ? ((ch % chCount) + chCount) % chCount : 0
    readonly property string chUrl: chCount ? String(tvFiles.get(chIdx, "fileUrl")) : Qt.resolvedUrl("room.jpg")
    readonly property bool chVideo: /\.(mp4|webm|mkv|mov)$/i.test(chUrl)
    readonly property bool chAnim: /\.(gif|webp)$/i.test(chUrl)
    readonly property string userName: users.count ? users.itemAt(userIdx)?.name ?? "" : userModel.lastUser
    property real power: 0

    FontLoader { id: pixel; source: "fonts/Silkscreen-Bold.ttf" }
    FolderListModel {
        id: tvFiles
        folder: Qt.resolvedUrl("tv")
        nameFilters: ["*.mp4", "*.webm", "*.mkv", "*.mov", "*.gif", "*.webp", "*.png", "*.jpg"]
        showDirs: false
    }

    // name lookups for the user/session models
    Repeater {
        id: users
        model: userModel
        Item {
            required property string name
            required property int index
            Component.onCompleted: if (name === userModel.lastUser) root.userIdx = index
        }
    }
    Repeater {
        id: sessions
        model: sessionModel
        Item { required property string name }
    }

    function flip(d) { dir = d; flick.restart(); chTimer.restart(); }
    function login() {
        if (busy || entering) return;
        busy = true;
        failed = false;
        sddm.login(userName, input.text, sessionIdx);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.failed = true;
            input.text = "";
            shakeAnim.restart();
        }
        function onLoginSucceeded() { root.entering = true; }
    }

    SequentialAnimation {
        running: true
        PauseAnimation { duration: 200 }
        NumberAnimation { target: root; property: "power"; from: 0; to: 1; duration: 750; easing.type: Easing.OutCubic }
    }

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

        Image {
            id: room
            anchors.fill: parent
            source: "room.jpg"
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

        Rectangle {
            id: spill
            anchors.centerIn: tv
            width: root.tvW * 1.25; height: root.tvH * 1.1
            radius: height / 2
            color: root.accent
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

        Rectangle {
            width: parent.width
            y: vcr.y + vcr.height
            height: parent.height - y
            color: "#0b0908"
            Rectangle { width: parent.width; height: 2; color: "#2e241e" }
        }

        Repeater {
            model: [-28, 24]
            Rectangle {
                required property int modelData
                x: tv.x + tv.width * 0.42 - width / 2
                y: tv.y - height + 6
                width: 3; height: root.tvH * 0.38
                color: "#9a9a9a"
                antialiasing: true
                transformOrigin: Item.Bottom
                rotation: modelData
            }
        }

        Rectangle {
            id: tv
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -root.height * 0.05
            width: root.tvW; height: root.tvH
            radius: width * 0.03
            gradient: Gradient {
                GradientStop { position: 0; color: "#3b302a" }
                GradientStop { position: 1; color: "#1a1513" }
            }
            border.color: "#4c3e35"; border.width: 2

            Rectangle {
                id: bezel
                x: tv.width * 0.045; y: tv.height * 0.07
                width: tv.width * 0.7; height: tv.height * 0.86
                radius: tv.width * 0.035
                color: "#0d0b0a"

                Item {
                    id: glass
                    anchors.fill: parent
                    anchors.margins: tv.width * 0.022
                    clip: true

                    Item {
                        id: tube
                        anchors.fill: parent
                        transform: Scale {
                            origin.x: tube.width / 2
                            origin.y: tube.height / 2
                            xScale: Math.min(1, root.power * 2.5)
                            yScale: root.power < 0.4 ? 0.006 : (root.power - 0.4) / 0.6
                        }

                        Item {
                            id: channel
                            anchors.fill: parent
                            VideoOutput {
                                id: vo
                                anchors.fill: parent
                                fillMode: VideoOutput.PreserveAspectCrop
                                visible: root.chVideo
                            }
                            MediaPlayer {
                                source: root.chVideo ? root.chUrl : ""
                                videoOutput: vo
                                loops: MediaPlayer.Infinite
                                onSourceChanged: if (source != "") play()
                            }
                            AnimatedImage {
                                anchors.fill: parent
                                visible: root.chAnim
                                source: root.chAnim ? root.chUrl : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Image {
                                anchors.fill: parent
                                visible: !root.chVideo && !root.chAnim
                                source: !root.chVideo && !root.chAnim ? root.chUrl : ""
                                fillMode: Image.PreserveAspectCrop
                            }
                        }
                        ShaderEffectSource { id: channelTex; sourceItem: channel; hideSource: true }

                        ShaderEffect {
                            id: crt
                            anchors.fill: parent
                            property var src: channelTex
                            property real time: 0
                            property real noise: 1
                            fragmentShader: "crt.frag.qsb"
                            NumberAnimation on time { from: 0; to: 10000; duration: 10000000; loops: Animation.Infinite }
                            NumberAnimation on noise { from: 1; to: 0; duration: 900; easing.type: Easing.OutQuad }
                        }

                        SequentialAnimation {
                            id: flick
                            NumberAnimation { target: crt; property: "noise"; to: 1; duration: 110 }
                            ScriptAction { script: root.ch += root.dir }
                            PauseAnimation { duration: 90 }
                            NumberAnimation { target: crt; property: "noise"; to: 0; duration: 420; easing.type: Easing.OutQuad }
                        }
                        Timer {
                            id: chTimer
                            interval: 9000
                            repeat: true
                            running: root.chCount > 1 && !root.entering
                            onTriggered: root.flip(1)
                        }

                        Timer { id: tick; interval: 1000; repeat: true; running: true; onTriggered: clockRow.now = new Date() }

                        Column {
                            id: clockCol
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height * 0.08
                            spacing: 2
                            Row {
                                id: clockRow
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 6
                                property date now: new Date()
                                readonly property var parts: Qt.formatDateTime(now, "hh:mm AP").split(" ")
                                Text {
                                    id: hm
                                    text: clockRow.parts[0]
                                    font.family: pixel.name
                                    font.pixelSize: glass.height * 0.16
                                    color: "white"
                                    style: Text.Outline; styleColor: "black"
                                }
                                Text {
                                    anchors.baseline: hm.baseline
                                    text: Qt.formatDateTime(clockRow.now, "ss")
                                    font.family: pixel.name
                                    font.pixelSize: glass.height * 0.065
                                    color: root.accent
                                    style: Text.Outline; styleColor: "black"
                                }
                                Text {
                                    anchors.baseline: hm.baseline
                                    text: clockRow.parts[1]
                                    font.family: pixel.name
                                    font.pixelSize: glass.height * 0.065
                                    color: "white"
                                    style: Text.Outline; styleColor: "black"
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(clockRow.now, "dddd  dd MMMM yyyy").toUpperCase()
                                font.family: pixel.name
                                font.pixelSize: glass.height * 0.038
                                color: "white"
                                style: Text.Outline; styleColor: "black"
                            }
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: parent.height * 0.15
                            spacing: 10

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: (users.count > 1 ? "\u25C0 " : "") + root.userName.toUpperCase() + (users.count > 1 ? " \u25B6" : "")
                                font.family: pixel.name
                                font.pixelSize: 20
                                color: root.accent
                                style: Text.Outline; styleColor: "black"
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.userIdx = (root.userIdx + 1) % Math.max(1, users.count)
                                }
                            }
                            Rectangle {
                                id: field
                                width: Math.max(glass.width * 0.46, 220); height: 42
                                radius: height / 2
                                color: "#e6000000"
                                border.width: 2
                                border.color: root.failed ? "#ff003c" : "white"
                                transform: Translate { id: shake }
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 18
                                    anchors.right: parent.right
                                    anchors.rightMargin: 18
                                    anchors.verticalCenter: parent.verticalCenter
                                    clip: true
                                    text: input.text.length ? "*".repeat(input.text.length) : (root.busy ? "verifying" : "password")
                                    font.family: pixel.name
                                    font.pixelSize: 18
                                    color: input.text.length ? "white" : "#8a8a82"
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.failed ? "ACCESS DENIED" : (keyboard.capsLock ? "CAPS LOCK" : " ")
                                font.family: pixel.name
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
                            opacity: root.power < 0.5 ? 1 : (1 - root.power) * 2
                        }
                    }
                }

                // rounds the glass corners by painting the bezel over them
                Rectangle {
                    anchors.fill: glass
                    anchors.margins: -tv.width * 0.022
                    color: "transparent"
                    radius: tv.width * 0.06
                    border.color: "#0d0b0a"
                    border.width: tv.width * 0.035
                }
            }

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
                            width: 4; height: parent.height * 0.62; radius: 2
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
                        Rectangle { width: tv.width * 0.13; height: 3; radius: 1.5; color: "#0c0a09" }
                    }
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 10; height: 10; radius: 5
                    color: root.failed ? "#ff003c" : "#7cff6b"
                }
            }
        }

        // VCR: session picker + power
        Rectangle {
            id: vcr
            anchors.horizontalCenter: tv.horizontalCenter
            y: tv.y + tv.height + 10
            width: tv.width * 0.94; height: tv.height * 0.13
            radius: 6
            color: "#131113"
            border.color: "#2b2628"; border.width: 2

            Row {
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.04
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                Repeater {
                    model: [
                        { t: "\u23FB OFF", f: () => sddm.powerOff(), ok: sddm.canPowerOff },
                        { t: "\u21BB REBOOT", f: () => sddm.reboot(), ok: sddm.canReboot }
                    ]
                    Text {
                        required property var modelData
                        visible: modelData.ok
                        text: modelData.t
                        font.family: pixel.name
                        font.pixelSize: vcr.height * 0.22
                        color: area.containsMouse ? root.accent : "#8a8a8a"
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: parent.modelData.f()
                        }
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: parent.width * 0.04
                anchors.verticalCenter: parent.verticalCenter
                width: deck.implicitWidth + 24; height: parent.height * 0.5
                radius: 4
                color: "#060506"
                Text {
                    id: deck
                    anchors.centerIn: parent
                    text: "\u25C0 " + ((sessions.count && sessions.itemAt(root.sessionIdx)?.name) || "session").toUpperCase() + " \u25B6"
                    font.family: pixel.name
                    font.pixelSize: vcr.height * 0.24
                    color: root.accent
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.sessionIdx = (root.sessionIdx + 1) % Math.max(1, sessions.count)
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

    ParallelAnimation {
        running: root.entering
        NumberAnimation { target: scene; property: "zoom"; to: 3.4; duration: 750; easing.type: Easing.InCubic }
        NumberAnimation { target: blackout; property: "opacity"; to: 1; duration: 750; easing.type: Easing.InQuart }
    }

    TextInput {
        id: input
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        onTextChanged: if (text !== "") root.failed = false
        Keys.onReturnPressed: root.login()
        Keys.onEnterPressed: root.login()
        Keys.onEscapePressed: text = ""
        Keys.onUpPressed: root.flip(1)
        Keys.onDownPressed: root.flip(-1)
        Keys.onTabPressed: root.sessionIdx = (root.sessionIdx + 1) % Math.max(1, sessions.count)
        Component.onCompleted: forceActiveFocus()
    }
}
