//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "./components"

// Default config: `qs` / `quickshell` loads this file.
// Clock face lives in components/StackedDigitalClock.qml,
// rolling strip in components/common/Digit.qml,
// OSD pill in components/VolumePopup.qml,
// dock in components/Dock.qml + DockPanel.qml (adapted from burninc0de.dock).
// Edit the `config` / `palette` blocks below to tweak.
//
// Layout: ShellRoot owns all shared state (clock time, volume) so there is
// exactly one ticker, one event stream and one writer no matter how many
// screens are attached. PanelWindows are thin per-screen views.

ShellRoot {
    id: shellRoot

    // ---- config (was Config.qml) ----
    readonly property real animationSpeed: 1.0 // 0 disables motion
    readonly property bool use24Hour: false
    readonly property int marginTop: 60
    readonly property int marginLeft: 60
    readonly property int marginRight: 60
    readonly property int marginBottom: 60
    readonly property string anchorPosition: "topLeft" // center, topLeft, topRight, bottomLeft, bottomRight
    readonly property int heroFontSize: 112
    property bool settingsOpen: false
    property bool clipOpen: false

    // ---- palette: color_palette_usage_guide.md roles ----
    // Primary #A7CBEB, Secondary #62829F (tracks/borders),
    // Text #2B4C6F, Bg #F8FAF9, Focus #A7B3EB, Accent #EBAA9D
    // NOTE: no `onX` names -- QML reserves on+Uppercase for signal handlers.
    readonly property color cOnSurface: "#2B4C6F"
    readonly property color cPrimary: "#A7CBEB"
    readonly property color cPrimaryContainer: "#62829F"
    readonly property color cOnPrimaryContainer: "#F8FAF9"

    // ---- shared wall-clock: fires on minute rollover, not every second ----
    // Single-shot, re-armed to the next minute boundary: ~60x fewer wakeups
    // than a 1s poll and no drift (every firing recomputes from wall clock,
    // so a late wake from suspend self-heals on the next fire).
    property date currentTime: new Date()
    Timer {
        id: clockTimer
        repeat: false
        onTriggered: {
            shellRoot.currentTime = new Date();
            clockTimer.scheduleNext();
        }
        function scheduleNext() {
            const now = new Date();
            interval = 60000 - (now.getSeconds() * 1000 + now.getMilliseconds()) + 50;
            restart();
        }
    }

    // ---- shared volume state: one stream/query/writer for all screens ----
    // NOTE: Quickshell's Pipewire audio proxy does not see external volume
    // changes on this system (reads 0 forever), so volume state is tracked
    // via pactl/wpctl instead.
    property real vol: 0
    property bool isMuted: false
    property bool showOsd: false
    property bool notifOpen: false
    property bool queryPending: false
    property var writerQueue: []

    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: shellRoot.showOsd = false
    }

    // Restart the event stream with backoff instead of hot-looping if
    // the sound server ever goes away.
    Timer {
        id: streamBackoff
        interval: 2000
        repeat: false
        onTriggered: eventStream.running = true
    }

    function poke() {
        shellRoot.showOsd = true;
        hideTimer.restart();
    }

    // Coalesced: overlapping audio events share one in-flight query.
    function queryVolume() {
        if (volQuery.running)
            shellRoot.queryPending = true;
        else
            volQuery.running = true;
    }

    // FIFO: rapid clicks/scrolls queue up, nothing is lost or reordered.
    function runWriter(cmd) {
        shellRoot.writerQueue.push(cmd);
        shellRoot.pumpWriter();
    }

    function pumpWriter() {
        if (!volWriter.running && shellRoot.writerQueue.length > 0) {
            volWriter.command = shellRoot.writerQueue.shift();
            volWriter.running = true;
        }
    }

    Component.onCompleted: {
        clockTimer.scheduleNext();
        queryVolume();
        // Reap `pactl subscribe` orphans from previous instances/reloads.
        // quickshell orphans children on reload/SIGTERM; only true orphans
        // (PPID 1) match, so live sibling streams are never touched.
        streamJanitor.running = true;
    }

    Process {
        id: streamJanitor
        command: ["sh", "-c", "for pat in \"[p]actl subscribe\" \"[w]l-paste --watch\"; do for p in $(pgrep -f \"$pat\" 2>/dev/null); do if [ \"$p\" != \"$$\" ] && [ \"$(ps -o ppid= -p \"$p\" 2>/dev/null | tr -d ' ')\" = \"1\" ]; then kill \"$p\" 2>/dev/null; fi; done; done"]
    }

    // Event stream: re-query on any sink/server change.
    Process {
        id: eventStream
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.includes("on sink") || data.includes("on server"))
                    shellRoot.queryVolume();
            }
        }
        onExited: streamBackoff.restart()
    }

    // One-shot state query. Only pops up when something changed.
    Process {
        id: volQuery
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Volume:\s*([0-9.]+)/);
                if (m) {
                    const v = parseFloat(m[1]);
                    const mu = text.includes("[MUTED]");
                    if (v !== shellRoot.vol || mu !== shellRoot.isMuted) {
                        shellRoot.vol = v;
                        shellRoot.isMuted = mu;
                        shellRoot.poke();
                    }
                }
            }
        }
        onExited: {
            if (shellRoot.queryPending) {
                shellRoot.queryPending = false;
                volQuery.running = true;
            }
        }
    }

    // Single writer fed by the FIFO queue above.
    Process {
        id: volWriter
        onExited: shellRoot.pumpWriter()
    }

    // ---- clipboard history: cliphist owned by a wl-paste --watch stream ----
    // Same one-stream pattern as audio. Panels query cliphist directly.
    // Orphaned watchers from previous instances are reaped by
    // streamJanitor above.
    Timer {
        id: clipBackoff
        interval: 2000
        repeat: false
        onTriggered: clipWatcher.running = true
    }

    Process {
        id: clipWatcher
        command: ["wl-paste", "--watch", "cliphist", "store"]
        running: true
        onExited: clipBackoff.restart()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: clockWin
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "m3qs"
            exclusionMode: ExclusionMode.Ignore

            color: "transparent"

            anchors {
                top: shellRoot.anchorPosition === "topLeft" || shellRoot.anchorPosition === "topRight"
                bottom: shellRoot.anchorPosition === "bottomLeft" || shellRoot.anchorPosition === "bottomRight"
                left: shellRoot.anchorPosition === "topLeft" || shellRoot.anchorPosition === "bottomLeft"
                right: shellRoot.anchorPosition === "topRight" || shellRoot.anchorPosition === "bottomRight"
            }
            margins {
                top: shellRoot.anchorPosition === "center" ? 0 : shellRoot.marginTop
                bottom: shellRoot.anchorPosition === "center" ? 0 : shellRoot.marginBottom
                left: shellRoot.anchorPosition === "center" ? 0 : shellRoot.marginLeft
                right: shellRoot.anchorPosition === "center" ? 0 : shellRoot.marginRight
            }

            implicitWidth: clock.implicitWidth
            implicitHeight: clock.implicitHeight

            // Clock floats over the wallpaper (currently Soft Sky Blue #A7CBEB):
            // only Deep Denim #2B4C6F passes 3:1 on it (5.23:1; slate 2.38,
            // cream 1.62, peach/periwinkle/mint ~1.2), so hero digits + date
            // pill all use denim-on-sky / cream-on-denim (8.47:1).
            StackedDigitalClock {
                id: clock
                anchors.centerIn: parent
                currentTime: shellRoot.currentTime
                use24Hour: shellRoot.use24Hour
                heroSize: shellRoot.heroFontSize
                animSpeed: shellRoot.animationSpeed
                cOnSurface: shellRoot.cOnSurface
                cPrimary: shellRoot.cOnSurface
                cPrimaryContainer: shellRoot.cOnSurface
                cOnPrimaryContainer: shellRoot.cOnPrimaryContainer
            }
        }
    }

    // ---- volume OSD: compact rounded pill, bottom-center ----
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: osdWin
            required property var modelData
            screen: modelData

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "m3qs-osd"
            exclusionMode: ExclusionMode.Ignore

            color: "transparent"

            anchors {
                bottom: true
            }
            margins {
                bottom: 90
            }

            implicitWidth: popup.implicitWidth
            implicitHeight: popup.implicitHeight

            visible: shellRoot.showOsd

            VolumePopup {
                id: popup
                anchors.centerIn: parent
                volume: shellRoot.vol
                muted: shellRoot.isMuted
                animSpeed: shellRoot.animationSpeed
                cOnSurface: shellRoot.cOnSurface
                cPrimary: shellRoot.cPrimary
                cTrack: shellRoot.cPrimaryContainer
            }

            // Scroll = volume up/down, click = mute toggle
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                onClicked: shellRoot.runWriter(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                onWheel: (wheel) => {
                    if (wheel.angleDelta.y > 0) {
                        if (shellRoot.isMuted)
                            shellRoot.runWriter(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
                        shellRoot.runWriter(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"]);
                    } else {
                        shellRoot.runWriter(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]);
                    }
                }
            }
        }
    }

    // ---- dock: burninc0de stealth dock, one panel per screen ----
    // Auto-hide on occupied workspaces, hover bottom edge to reveal.
    // Pin/reorder/settings state lives under ~/.local/state/omarchy/burninc0de.dock.
    Dock {
        cOnSurface: shellRoot.cOnSurface
        cPrimary: shellRoot.cPrimary
        cTrack: shellRoot.cPrimaryContainer
        cBg: "#F8FAF9"
        cHover: "#A7B3EB"
        cMuted: shellRoot.cPrimaryContainer
    }

    TopBar {
        id: topBar
        barSideMargin: 365
        currentTime: shellRoot.currentTime
        use24Hour: shellRoot.use24Hour
        animSpeed: shellRoot.animationSpeed
        notifOpen: shellRoot.notifOpen
        notifCount: notifCenter.count
        onNotifToggled: {
            shellRoot.notifOpen = !shellRoot.notifOpen;
            if (shellRoot.notifOpen) {
                shellRoot.settingsOpen = false;
                shellRoot.clipOpen = false;
            }
        }
        settingsOpen: shellRoot.settingsOpen
        onSettingsToggled: {
            shellRoot.settingsOpen = !shellRoot.settingsOpen;
            if (shellRoot.settingsOpen) {
                shellRoot.notifOpen = false;
                shellRoot.clipOpen = false;
            }
        }
        clipOpen: shellRoot.clipOpen
        onClipToggled: {
            shellRoot.clipOpen = !shellRoot.clipOpen;
            if (shellRoot.clipOpen) {
                shellRoot.notifOpen = false;
                shellRoot.settingsOpen = false;
            }
        }
        cBg: "#FFFFFF" // white bar
        cText: shellRoot.cOnSurface
        cBorder: shellRoot.cPrimaryContainer
    }

    // ---- notification center: dropdown card per screen ----
    // Owns the NotificationServer (replaces dunst).
    NotifCenter {
        id: notifCenter
        open: shellRoot.notifOpen && !topBar.isIsland
        onCloseRequested: shellRoot.notifOpen = false
        animSpeed: shellRoot.animationSpeed
    }

    // ---- settings panel: dropdown card per screen ----
    SettingsPanel {
        id: settingsPanel
        open: shellRoot.settingsOpen && !topBar.isIsland
        onCloseRequested: shellRoot.settingsOpen = false
        animSpeed: shellRoot.animationSpeed
        rightMargin: topBar.barSideMargin
        cBg: "#FFFFFF"
        cBorder: shellRoot.cPrimaryContainer
        cText: shellRoot.cOnSurface
        cMuted: shellRoot.cPrimaryContainer
        volume: shellRoot.vol
        muted: shellRoot.isMuted
        // Slider commits on release (one call per drag); unmute first so a
        // drag from muted behaves like the OSD scroll handler.
        onVolumeSetRequested: (v) => {
            if (shellRoot.isMuted)
                shellRoot.runWriter(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
            shellRoot.runWriter(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1.5, v)).toFixed(3)]);
        }
        onMuteToggled: shellRoot.runWriter(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    }

    // ---- clipboard history: dropdown card per screen ----
    ClipboardPanel {
        id: clipPanel
        open: shellRoot.clipOpen && !topBar.isIsland
        onCloseRequested: shellRoot.clipOpen = false
        animSpeed: shellRoot.animationSpeed
        rightMargin: topBar.barSideMargin
        cBg: "#FFFFFF"
        cBorder: shellRoot.cPrimaryContainer
        cText: shellRoot.cOnSurface
        cMuted: shellRoot.cPrimaryContainer
    }
}
