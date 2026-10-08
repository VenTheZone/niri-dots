pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/niri/wallpaper/posters"
    readonly property var modes: ["fade", "wipe", "grow", "outer", "clock", "random"]

    property var walls: []
    property bool postersLoaded: false
    property bool stateLoaded: false
    readonly property var current: postersLoaded && stateLoaded
        ? (walls.find(w => w.file === st.file) ?? walls[0] ?? null) : null
    readonly property color accent: current ? current.accent : "#f3e600"

    property alias mode: st.mode
    property alias reveal: st.reveal
    property int transMode: 0
    property bool pickerOpen: false

    readonly property string display: abril.name
    readonly property string pixel: silk.name

    FontLoader { id: abril; source: Qt.resolvedUrl("fonts/AbrilFatface-Regular.ttf") }
    FontLoader { id: silk; source: Qt.resolvedUrl("fonts/Silkscreen-Bold.ttf") }

    function url(w) { return w ? "file://" + dir + "/" + w.file : "" }

    // fastfetch shows whichever poster is live
    onCurrentChanged: if (current)
        Quickshell.execDetached(["ln", "-sfn", dir + "/" + current.file,
                                 Quickshell.env("HOME") + "/.cache/rice-poster.jpg"])

    function apply(file) {
        if (!file || file === current?.file) return;
        const m = modes.indexOf(st.mode);
        transMode = m >= 0 && m < 5 ? m : Math.floor(Math.random() * 5);
        st.file = file;
    }

    function step(n) {
        if (!walls.length) return;
        const i = Math.max(0, walls.indexOf(current));
        apply(walls[(i + n + walls.length) % walls.length].file);
    }

    FileView {
        path: root.dir + "/posters.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.walls = JSON.parse(text()); } catch (e) { console.warn("posters.json:", e); }
            root.postersLoaded = true;
        }
        onLoadFailed: root.postersLoaded = true
    }

    FileView {
        path: Quickshell.statePath("state.json")
        onAdapterUpdated: writeAdapter()
        onLoaded: root.stateLoaded = true
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) writeAdapter();
            root.stateLoaded = true;
        }

        JsonAdapter {
            id: st
            property string file: ""
            property string mode: "random"
            property bool reveal: false
        }
    }

    IpcHandler {
        target: "wall"
        function picker(): void { root.pickerOpen = !root.pickerOpen; }
        function reveal(): void { root.reveal = !root.reveal; }
        function next(): void { root.step(1); }
        function prev(): void { root.step(-1); }
        function set(file: string): void { root.apply(file); }
    }

    // fuzzel in the current poster's accent
    IpcHandler {
        target: "launcher"
        function open(): void {
            const a = root.accent.toString().slice(1) + "ff";
            Quickshell.execDetached(["fuzzel", "--border-color", a, "--selection-color", a,
                                     "--match-color", a, "--prompt-color", a]);
        }
    }
}
