import QtQuick
import QtQuick.Effects

// lock screen "Neon Room" look: rainy city window on the left wall, neon sign on the right.
// the TV never covers more than the middle half of the screen, so both stay in the outer quarters
Item {
    id: room

    // ---- rainy window ----
    Item {
        id: win
        x: room.width * 0.045; y: room.height * 0.12
        width: room.width * 0.19; height: room.height * 0.5
        opacity: 0.85
        // slightly out of focus, like the rest of the room
        layer.enabled: true
        layer.effect: MultiEffect { blurEnabled: true; blur: 0.2; blurMax: 16 }

        Rectangle {
            id: glassPane
            anchors.fill: parent
            clip: true
            anchors.margins: 10
            gradient: Gradient {
                GradientStop { position: 0; color: "#070a1f" }
                GradientStop { position: 0.65; color: "#22093a" }
                GradientStop { position: 1; color: "#4a0f45" }
            }

            // skyline, new one every lock
            Row {
                anchors.bottom: parent.bottom
                Repeater {
                    model: 12
                    Rectangle {
                        id: bld
                        width: glassPane.width * (0.07 + Math.random() * 0.08)
                        height: glassPane.height * (0.2 + Math.random() * 0.5)
                        anchors.bottom: parent.bottom
                        color: "#06050b"
                        Repeater {
                            model: Math.max(0, Math.floor(bld.height / 9))
                            Rectangle {
                                x: 3 + Math.floor(Math.random() * Math.max(1, (bld.width - 6) / 6)) * 6
                                y: 6 + Math.floor(Math.random() * Math.max(1, (bld.height - 10) / 8)) * 8
                                width: 3; height: 4
                                color: ["#f3e600", "#00f0ff", "#ff2a9d", "#ffd9a0"][Math.floor(Math.random() * 4)]
                                opacity: 0.25 + Math.random() * 0.5
                            }
                        }
                    }
                }
            }

            // rain: the whole field is tilted so streaks fall along the slant
            Item {
                anchors.centerIn: parent
                width: parent.width * 1.5; height: parent.height * 1.3
                rotation: 14
                Repeater {
                    model: 90
                    Rectangle {
                        x: Math.random() * parent.width
                        width: 1; height: 10 + Math.random() * 22
                        color: "#a8dcff"
                        opacity: 0.12 + Math.random() * 0.3
                        NumberAnimation on y {
                            from: -40 - Math.random() * 400
                            to: glassPane.height * 1.4
                            duration: 450 + Math.random() * 450
                            loops: Animation.Infinite
                        }
                    }
                }
            }

            // drops stuck on the glass
            Repeater {
                model: 28
                Rectangle {
                    x: Math.random() * glassPane.width; y: Math.random() * glassPane.height
                    width: 2 + Math.random() * 4; height: width * 1.3
                    radius: width / 2
                    color: "white"
                    opacity: 0.12
                }
            }

            // the sign across the room reflecting in the glass
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "#00ff2a9d" }
                    GradientStop { position: 1; color: "#22ff2a9d" }
                }
            }
        }

        // frame + mullions
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "#17121b"; border.width: 10
        }
        Rectangle { anchors.horizontalCenter: parent.horizontalCenter; width: 8; height: parent.height; color: "#17121b" }
        Rectangle { y: parent.height * 0.42; width: parent.width; height: 8; color: "#17121b" }
    }
    Rectangle {
        x: win.x - 12; y: win.y + win.height
        width: win.width + 24; height: 10
        color: "#1d171f"
    }

    // ---- neon sign ----
    component Neon: Text {
        id: tube
        property color glow
        font.family: Rice.display
        color: Qt.lighter(glow, 1.55)
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: tube.glow
            shadowBlur: 1
            blurMax: 40
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
            shadowScale: 1.04
        }
    }

    Item {
        id: sign
        width: Math.max(night.implicitWidth, city.implicitWidth)
        height: night.implicitHeight + city.implicitHeight * 0.8
        x: room.width * 0.875 - width / 2
        y: room.height * 0.17

        // glow washing the wall behind the sign
        Rectangle {
            id: wash
            anchors.centerIn: parent
            width: parent.width * 1.6; height: parent.height * 1.6
            radius: height / 2
            color: "#ff2a9d"
            visible: false
        }
        MultiEffect {
            anchors.fill: wash
            source: wash
            autoPaddingEnabled: true
            blurEnabled: true; blur: 1; blurMax: 100
            opacity: 0.18 * night.opacity
        }

        // hanging wires
        Repeater {
            model: [0.2, 0.8]
            Rectangle {
                required property real modelData
                x: sign.width * modelData; y: -sign.y
                width: 1; height: sign.y
                color: "#3a3036"
            }
        }

        Neon {
            id: night
            anchors.horizontalCenter: parent.horizontalCenter
            text: "NIGHT"
            font.pixelSize: room.height * 0.085
            glow: "#ff2a9d"
            // mains hum
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 0.88; duration: 1400 }
                NumberAnimation { to: 1; duration: 1400 }
            }
        }
        Neon {
            id: city
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: night.bottom
            anchors.topMargin: -night.implicitHeight * 0.2
            text: "CITY"
            font.pixelSize: room.height * 0.085
            glow: "#00f0ff"
            // dying tube
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation { duration: 3800 }
                PropertyAction { value: 0.15 }
                PauseAnimation { duration: 60 }
                PropertyAction { value: 1 }
                PauseAnimation { duration: 110 }
                PropertyAction { value: 0.05 }
                PauseAnimation { duration: 180 }
                PropertyAction { value: 1 }
                PauseAnimation { duration: 2400 }
                PropertyAction { value: 0.3 }
                PauseAnimation { duration: 50 }
                PropertyAction { value: 1 }
            }
        }
    }
}
