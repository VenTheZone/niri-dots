import QtQuick
import Quickshell

// lock screen ERROR (wrong password) and BREACH PROTOCOL (right password) screens.
// one copy lives in the TV, one in the HUD; both just follow the animated state on `view`
Item {
    id: alerts

    // the lock surface: errShow, strobe, hackLines, hackProgress, granted, blink
    property var view
    property bool hacking
    property string failText

    // ---- wrong password: black ICE hijacks the feed ----
    Item {
        id: errLayer
        anchors.fill: parent
        opacity: alerts.view.errShow
        visible: opacity > 0

        Rectangle { anchors.fill: parent; color: "#140005" }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 8
                Text {
                    required property int index
                    text: "ERROR  ".repeat(20)
                    font.family: Rice.pixel
                    font.pixelSize: alerts.height / 9
                    color: "#ff003c"
                    opacity: 0.14
                    NumberAnimation on x {
                        running: errLayer.visible
                        from: index % 2 ? -alerts.width : 0
                        to: index % 2 ? 0 : -alerts.width
                        duration: 3000
                    }
                }
            }
        }

        Rectangle { anchors.fill: parent; color: "#ff003c"; opacity: alerts.view.strobe }

        Column {
            anchors.centerIn: parent
            spacing: alerts.height * 0.03

            Grid {
                id: skull
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 13
                readonly property real px: Math.round(alerts.height * 0.026)
                Repeater {
                    model: ["...XXXXXXX...",
                            ".XXXXXXXXXXX.",
                            "XXXXXXXXXXXXX",
                            "XXXXXXXXXXXXX",
                            "XXoooXXXoooXX",
                            "XXoooXXXoooXX",
                            "XXXoXXXXXoXXX",
                            "XXXXXX.XXXXXX",
                            ".XXXX...XXXX.",
                            "..XXXXXXXXX..",
                            "..X.X.X.X.X..",
                            "...XXXXXXX..."].join("").split("")
                    Rectangle {
                        required property string modelData
                        width: skull.px; height: skull.px
                        color: modelData === "X" ? "#ff003c"
                            : modelData === "o" && alerts.view.blink ? "#ffd0d8" : "transparent"
                    }
                }
                SequentialAnimation on scale {
                    running: errLayer.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.12; duration: 90 }
                    NumberAnimation { to: 1; duration: 360; easing.type: Easing.OutQuad }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: alerts.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                fontSizeMode: Text.HorizontalFit
                text: "ERROR  ERROR"
                font.family: Rice.pixel
                font.pixelSize: alerts.height * 0.13
                color: "#ff003c"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: alerts.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: alerts.failText
                font.family: Rice.pixel
                font.pixelSize: alerts.height * 0.045
                color: "#ffd0d8"
            }
        }
    }

    // ---- right password: breach protocol, then ACCESS GRANTED ----
    Item {
        id: hackLayer
        anchors.fill: parent
        visible: alerts.hacking
        readonly property real fs: alerts.height * 0.042

        Rectangle { anchors.fill: parent; color: "#020a03" }

        Text {
            id: hexRain
            anchors.fill: parent
            wrapMode: Text.WrapAnywhere
            clip: true
            font.family: Rice.pixel
            font.pixelSize: hackLayer.fs * 0.8
            color: "#7cff6b"
            opacity: 0.12
            Timer {
                interval: 70; repeat: true; triggeredOnStart: true
                running: hackLayer.visible
                onTriggered: {
                    let s = "";
                    for (let i = 0; i < 2400; i++)
                        s += "0123456789ABCDEF"[Math.floor(Math.random() * 16)] + (i % 2 ? " " : "");
                    hexRain.text = s;
                }
            }
        }

        Column {
            anchors.centerIn: parent
            width: Math.min(alerts.width * 0.74, alerts.height * 0.9)
            spacing: hackLayer.fs * 0.4
            visible: !alerts.view.granted

            Text {
                text: "BREACH PROTOCOL"
                font.family: Rice.pixel
                font.pixelSize: hackLayer.fs * 1.4
                color: "white"
            }
            Repeater {
                model: ["JACK IN", "SCAN ICE", "INJECT DAEMON", "BYPASS FIREWALL", "CRACK KEYS"]
                Item {
                    required property string modelData
                    required property int index
                    width: parent.width; height: hackLayer.fs
                    opacity: index < alerts.view.hackLines ? 1 : 0
                    Text {
                        text: "> " + parent.modelData
                        font.family: Rice.pixel
                        font.pixelSize: hackLayer.fs
                        color: "#7cff6b"
                    }
                    Text {
                        anchors.right: parent.right
                        text: "OK"
                        font.family: Rice.pixel
                        font.pixelSize: hackLayer.fs
                        color: "white"
                    }
                }
            }
            Rectangle {
                width: parent.width; height: hackLayer.fs
                color: "transparent"
                border.color: "#7cff6b"; border.width: 2
                Rectangle {
                    x: 4; y: 4
                    height: parent.height - 8
                    width: (parent.width - 8) * alerts.view.hackProgress
                    color: "#7cff6b"
                }
            }
            Text {
                text: "UPLOAD " + Math.round(alerts.view.hackProgress * 100) + "%"
                font.family: Rice.pixel
                font.pixelSize: hackLayer.fs
                color: "#7cff6b"
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: alerts.height * 0.03
            visible: alerts.view.granted
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: alerts.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                fontSizeMode: Text.HorizontalFit
                text: "ACCESS GRANTED"
                font.family: Rice.pixel
                font.pixelSize: alerts.height * 0.12
                color: "#7cff6b"
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: alerts.width * 0.8
                horizontalAlignment: Text.AlignHCenter
                fontSizeMode: Text.HorizontalFit
                text: "SYSTEM BREACHED // WELCOME BACK, " + (Quickshell.env("USER") ?? "").toUpperCase()
                font.family: Rice.pixel
                font.pixelSize: hackLayer.fs
                color: "white"
            }
        }
    }
}
