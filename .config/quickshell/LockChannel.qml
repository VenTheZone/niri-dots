import QtQuick
import QtMultimedia

// one lock screen channel (video, gif/webp or still), cropped to fill. used by the TV and the HUD
Loader {
    id: ch

    property string url

    // derived from the url right where it's used, so the type never lags behind the file
    function kindOf(u) {
        return /\.(mp4|webm|mkv|mov)$/i.test(u) ? "video" : /\.(gif|webp)$/i.test(u) ? "anim" : "image";
    }

    sourceComponent: kindOf(url) === "video" ? video : kindOf(url) === "anim" ? anim : still

    Component {
        id: video
        Item {
            VideoOutput {
                id: vo
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
            }
            // no audioOutput: the lock screen stays silent
            MediaPlayer {
                source: ch.url
                videoOutput: vo
                loops: MediaPlayer.Infinite
                onSourceChanged: play()
                Component.onCompleted: play()
            }
        }
    }
    Component {
        id: anim
        AnimatedImage {
            source: ch.kindOf(ch.url) === "anim" ? ch.url : ""
            fillMode: Image.PreserveAspectCrop
        }
    }
    Component {
        id: still
        Image {
            source: ch.kindOf(ch.url) === "image" ? ch.url : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
        }
    }
}
