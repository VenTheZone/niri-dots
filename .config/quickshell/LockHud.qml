import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Mpris

// lock screen "Netrunner HUD" look: the TV channel full screen through the CRT shader,
// with brackets, live readouts, a big clock and the access code prompt on top
Item {
    id: hud

    // the lock surface: channel, noise, power, shake, blink + the alert state LockAlerts reads
    property var view
    // the lock scope: mask, busy, failed, unlocking, pamMsg, attempts
    property var lock
    property date date

    readonly property real m: Math.round(height * 0.035)
    readonly property real fs: Math.max(12, Math.round(height * 0.015))
    readonly property color cyan: "#00f0ff"
    readonly property color red: "#ff003c"

    property string host: ""
    property string ssid: ""
    property int up: 0

    readonly property var bat: UPower.displayDevice
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function uptime(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s / 3600) % 24, mn = Math.floor(s / 60) % 60;
        return (d ? d + "D " : "") + String(h).padStart(2, "0") + "H " + String(mn).padStart(2, "0") + "M";
    }

    // echo so an empty ssid still takes its own line
    Process {
        id: sys
        // fetch at lock time so the readouts are filled before the HUD rotates in
        running: true
        command: ["sh", "-c", "echo \"$(uname -n)\"; echo \"$(nmcli -t -f active,ssid dev wifi 2>/dev/null | sed -n 's/^yes://p' | head -1)\"; cut -d. -f1 /proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n");
                hud.host = l[0];
                hud.ssid = l[1] || "OFFLINE";
                hud.up = parseInt(l[2]) || 0;
            }
        }
    }
    Timer { interval: 30000; repeat: true; running: hud.visible; onTriggered: sys.running = true }

    component Label: Text {
        font.family: Rice.pixel
        color: "white"
    }

    // four L-shaped corners hugging whatever they fill
    component Brackets: Item {
        id: br
        property real len: 20
        property real thick: 2
        property color c: Rice.accent
        property bool dots: false
        Repeater {
            model: [[0, 0, 0], [1, 0, 90], [1, 1, 180], [0, 1, 270]]
            Item {
                required property var modelData
                width: br.len; height: br.len
                x: modelData[0] ? br.width - br.len : 0
                y: modelData[1] ? br.height - br.len : 0
                rotation: modelData[2]
                Rectangle { width: br.len; height: br.thick; color: br.c }
                Rectangle { width: br.thick; height: br.len; color: br.c }
                Rectangle { x: 8; y: 8; width: 6; height: 6; color: "#00f0ff"; visible: br.dots }
            }
        }
    }

    // black behind the screen so the power-off collapses into darkness
    Rectangle { anchors.fill: parent; color: "black" }

    Item {
        id: screen
        anchors.fill: parent
        transform: [
            Translate { x: hud.view.shake },
            // same switch-off as the TV tube: flash, line, dot
            Scale {
                origin.x: screen.width / 2
                origin.y: screen.height / 2
                xScale: Math.min(1, hud.view.power * 2.5)
                yScale: hud.view.power < 0.4 ? 0.006 : (hud.view.power - 0.4) / 0.6
            }
        ]

        // ---- the feed: channel + alerts, run through the CRT shader ----
        Item {
            id: feed
            anchors.fill: parent
            LockChannel {
                anchors.fill: parent
                active: hud.visible
                url: hud.view.chUrl
            }
            Rectangle { anchors.fill: parent; color: "black"; opacity: 0.55 }
            LockAlerts {
                anchors.fill: parent
                view: hud.view
                hacking: hud.lock.unlocking
                failText: hud.view.failText
            }
        }
        ShaderEffectSource { id: feedTex; sourceItem: feed; hideSource: true }
        ShaderEffect {
            anchors.fill: parent
            property var src: feedTex
            property real time: 0
            property real noise: hud.view.noise
            fragmentShader: Qt.resolvedUrl("shaders/crt.frag.qsb")
            NumberAnimation on time { from: 0; to: 10000; duration: 10000000; loops: Animation.Infinite }
        }

        // ---- frame ----
        Brackets {
            anchors.fill: parent
            anchors.margins: hud.m
            len: hud.height * 0.07
            thick: 3
            dots: true
        }
        Repeater {
            model: [0, 1]
            Rectangle {
                required property int modelData
                x: hud.m + hud.height * 0.09
                width: hud.width - 2 * x
                y: modelData ? hud.height - hud.m : hud.m
                height: 1
                color: Rice.accent
                opacity: 0.35
            }
        }
        // ruler ticks down the left edge
        Column {
            x: hud.m; y: hud.height * 0.3
            spacing: hud.height * 0.016
            Repeater {
                model: 22
                Rectangle {
                    required property int index
                    width: index % 5 ? 8 : 18; height: 1
                    color: hud.cyan
                    opacity: 0.5
                }
            }
        }

        // top left: who's jacked in
        Column {
            x: hud.m + hud.height * 0.035; y: hud.m + hud.height * 0.03
            spacing: hud.fs * 0.5
            Label {
                text: "NETRUNNER // SESSION LOCKED"
                font.pixelSize: hud.fs * 1.5
                color: Rice.accent
            }
            Label {
                text: (Quickshell.env("USER") + "@" + hud.host).toUpperCase()
                font.pixelSize: hud.fs
            }
            Row {
                spacing: hud.fs * 0.6
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: hud.fs * 0.6; height: width; radius: width / 2
                    color: hud.red
                    opacity: hud.view.blink ? 1 : 0.15
                }
                Label { text: "ICE ACTIVE"; font.pixelSize: hud.fs; color: hud.red }
            }
        }

        // top right: live readouts
        Column {
            anchors.right: parent.right
            anchors.rightMargin: hud.m + hud.height * 0.035
            y: hud.m + hud.height * 0.03
            spacing: hud.fs * 0.5
            Repeater {
                model: [
                    ...(hud.bat && hud.bat.isLaptopBattery
                        ? [["PWR", Math.round(hud.bat.percentage * 100) + "%"
                            + (hud.bat.state === UPowerDeviceState.Charging ? " +AC" : "")]] : []),
                    ["NET", hud.ssid.toUpperCase()],
                    ["UP", hud.uptime(hud.up)]
                ]
                Row {
                    required property var modelData
                    anchors.right: parent.right
                    spacing: hud.fs * 0.8
                    Label { text: parent.modelData[0]; font.pixelSize: hud.fs * 1.2; color: hud.cyan }
                    Label { text: parent.modelData[1]; font.pixelSize: hud.fs * 1.2 }
                }
            }
        }

        // bottom left: now playing
        Column {
            x: hud.m + hud.height * 0.035
            anchors.bottom: ticker.top
            anchors.bottomMargin: hud.fs
            spacing: hud.fs * 0.4
            Label { text: "AUDIO FEED"; font.pixelSize: hud.fs; color: hud.cyan }
            Label {
                width: hud.width * 0.3
                elide: Text.ElideRight
                text: hud.player && hud.player.trackTitle
                    ? (">> " + (hud.player.trackArtist ? hud.player.trackArtist + " - " : "") + hud.player.trackTitle).toUpperCase()
                    : "NO SIGNAL"
                font.pixelSize: hud.fs * 1.2
                color: hud.player?.isPlaying ? "white" : "#8a8a8a"
            }
        }

        // bottom: data ticker, two copies so the loop is seamless
        Item {
            id: ticker
            x: hud.m + hud.height * 0.09
            width: hud.width - 2 * x
            height: hud.fs * 2
            y: hud.height - hud.m - height - 6
            clip: true
            Row {
                id: tape
                Repeater {
                    model: 2
                    Label {
                        text: "  ///  ICE: ACTIVE  ///  TRACE: NONE  ///  DAEMONS: IDLE  ///  ARASAKA SUBNET: SILENT  ///  "
                            + "NCPD SCANNER: QUIET  ///  BREACH WINDOW: CLOSED  ///  NODE "
                            + (hud.host || "LOCAL").toUpperCase() + ": LOCKED"
                        font.pixelSize: hud.fs
                        color: Rice.accent
                        opacity: 0.7
                    }
                }
                // starts once the hostname is in, so the loop length is final
                NumberAnimation on x {
                    running: hud.host !== ""
                    from: 0; to: -tape.width / 2
                    duration: tape.width * 12
                    loops: Animation.Infinite
                }
            }
        }

        // ---- center: clock + access code ----
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -hud.height * 0.03
            spacing: hud.height * 0.012
            visible: hud.view.errShow === 0 && !hud.lock.unlocking

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: hud.fs * 0.8
                readonly property var parts: Qt.formatDateTime(hud.date, "hh:mm AP").split(" ")
                Label {
                    id: hm
                    text: parent.parts[0]
                    font.pixelSize: hud.height * 0.16
                    style: Text.Outline; styleColor: "black"
                }
                Label {
                    anchors.baseline: hm.baseline
                    text: Qt.formatDateTime(hud.date, "ss")
                    font.pixelSize: hud.height * 0.06
                    color: Rice.accent
                    style: Text.Outline; styleColor: "black"
                }
                Label {
                    anchors.baseline: hm.baseline
                    text: parent.parts[1]
                    font.pixelSize: hud.height * 0.06
                    style: Text.Outline; styleColor: "black"
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(hud.date, "dddd  dd MMMM yyyy").toUpperCase()
                font.pixelSize: hud.fs * 1.4
                color: hud.cyan
                style: Text.Outline; styleColor: "black"
            }

            Item { width: 1; height: hud.height * 0.04 }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: hud.lock.busy ? "DECRYPTING..." : "ENTER ACCESS CODE"
                font.pixelSize: hud.fs * 1.2
                color: hud.lock.busy ? Rice.accent : hud.cyan
            }
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: hud.height * 0.62; height: hud.fs * 3.6
                Rectangle { anchors.fill: parent; color: "#b3000000" }
                Brackets {
                    anchors.fill: parent
                    len: parent.height * 0.4
                    thick: 2
                    c: hud.lock.failed ? hud.red : Rice.accent
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: hud.fs * 1.4
                    spacing: hud.fs
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ACCESS CODE >"
                        font.pixelSize: hud.fs * 1.2
                        color: hud.cyan
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: hud.lock.mask + (hud.view.blink && !hud.lock.busy ? "_" : " ")
                        font.pixelSize: hud.fs * 1.5
                        color: hud.lock.busy ? Rice.accent : "white"
                    }
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                width: hud.height * 0.9
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: hud.lock.failed
                text: hud.lock.pamMsg ? hud.lock.pamMsg.toUpperCase()
                    : "ACCESS DENIED  //  ATTEMPT " + String(hud.lock.attempts).padStart(2, "0")
                font.pixelSize: hud.fs * 1.1
                color: hud.red
                style: Text.Outline; styleColor: "black"
            }
        }

        // power on/off flash
        Rectangle {
            anchors.fill: parent
            color: "white"
            opacity: hud.view.power < 0.5 ? 1 : (1 - hud.view.power) * 2
        }
    }
}
