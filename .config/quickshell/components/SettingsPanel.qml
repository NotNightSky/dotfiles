import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Qt5Compat.GraphicalEffects

// Settings popdown, modeled on NotifCenter.qml: one dropdown card per screen
// while `open`, outside-click-to-close via focus grab, exit animation via the
// `closing` state. The card drops down from the right, under the top-bar gear
// icon. Content to be added; the shell (mask, grab, animation) is intact.
Item {
    id: root

    property bool open: false
    property real animSpeed: 1.0
    property int topOffset: 40
    property int cardWidth: 300

    property color cBg: "#FFFFFF"
    property color cBorder: "#62829F"
    property color cText: "#2B4C6F"
    property color cMuted: "#62829F"
    // Right offset of the card: bound to the bar's side margin so the card
    // drops down from under the gear icon.
    property int rightMargin: 365

    signal closeRequested()

    // User header: face + name from the session, uptime from /proc/uptime.
    readonly property string userName: Quickshell.env("USER") || "user"
    readonly property string faceUrl: "file://" + (Quickshell.env("HOME") || ("/home/" + userName)) + "/.face"
    property bool hasFace: true
    property string uptimeText: ""

    function updateUptime() {
        if (!uptimeQuery.running)
            uptimeQuery.running = true;
    }

    function parseUptime(text) {
        const secs = Math.floor(parseFloat(text.split(" ")[0]));
        if (isNaN(secs))
            return;
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        const hs = h + (h === 1 ? " hour" : " hours");
        const ms = m + (m === 1 ? " minute" : " minutes");
        root.uptimeText = h > 0 ? hs + ", " + ms : ms;
    }

    // Volume slider (state lives in shell.qml, like the OSD volume).
    property real volume: 0
    property bool muted: false
    // Local drag preview (0..1); -1 means "not dragging, show shell state".
    property real sliderPreview: -1
    signal volumeSetRequested(real value)
    signal muteToggled()

    // Shared row: ethernet toggle (nmcli) + power profile switcher.
    property string ethDevice: ""
    property bool ethConnected: false
    property bool ethAvailable: false

    property string powerProfile: "" // performance | balanced | power-saver
    readonly property bool powerAvailable: root.powerProfile !== ""
    // U+F511 speedometer, U+F1883 scale, U+F2AA leaf.
    readonly property string powerIcon: root.powerProfile === "performance" ? "" : root.powerProfile === "power-saver" ? "" : ""
    readonly property string powerLabel: root.powerProfile === "performance" ? "Performance" : root.powerProfile === "power-saver" ? "Power Saver" : "Balanced"

    function parseEth(text) {
        let dev = "", conn = false, found = false;
        for (const line of text.split("\n")) {
            const p = line.split(":");
            if (p.length < 3 || p[1] !== "ethernet")
                continue;
            found = true;
            if (p[2] === "connected") {
                dev = p[0];
                conn = true;
                break;
            }
            if (!dev)
                dev = p[0];
        }
        root.ethAvailable = found;
        if (found) {
            root.ethDevice = dev;
            root.ethConnected = conn;
        }
    }

    function toggleEth() {
        if (!root.ethAvailable || root.ethDevice === "" || ethToggle.running)
            return;
        // Optimistic flip; the refresh poll reconciles if it fails.
        const was = root.ethConnected;
        root.ethConnected = !was;
        ethToggle.command = was ? ["nmcli", "device", "disconnect", root.ethDevice]
                                : ["nmcli", "device", "connect", root.ethDevice];
        ethToggle.running = true;
    }

    function cyclePower() {
        if (!root.powerAvailable || powerSet.running)
            return;
        const order = ["balanced", "performance", "power-saver"];
        const next = order[(order.indexOf(root.powerProfile) + 1) % order.length];
        powerSet.command = ["powerprofilesctl", "set", next];
        powerSet.running = true;
    }

    Process {
        id: ethQuery
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        stdout: StdioCollector { onStreamFinished: root.parseEth(text) }
        onExited: (code) => {
            if (code !== 0)
                root.ethAvailable = false;
        }
    }
    Process {
        id: ethToggle
        onExited: ethRefreshTimer.restart()
    }
    Timer {
        id: ethRefreshTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (!ethQuery.running)
                ethQuery.running = true;
        }
    }
    Timer {
        id: ethPollTimer
        interval: 15000
        repeat: true
        running: root.open
        onTriggered: {
            if (!ethQuery.running)
                ethQuery.running = true;
        }
    }

    Process {
        id: powerQuery
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim();
                root.powerProfile = (s === "performance" || s === "balanced" || s === "power-saver") ? s : "";
            }
        }
        onExited: (code) => {
            if (code !== 0)
                root.powerProfile = "";
        }
    }
    Process {
        id: powerSet
        onExited: {
            if (!powerQuery.running)
                powerQuery.running = true;
        }
    }
    Timer {
        id: powerPollTimer
        interval: 15000
        repeat: true
        running: root.open
        onTriggered: {
            if (!powerQuery.running)
                powerQuery.running = true;
        }
    }

    // Spotify center (self-contained via playerctl).
    property string spTitle: ""
    property string spArtist: ""
    property string spArtUrl: ""
    property real spLength: 0 // track length, seconds
    property real spPosBase: 0 // last known position, seconds
    property real spPosAt: 0 // Date.now() ms when spPosBase was recorded
    property string spStatus: "" // Playing | Paused
    property real spSeekPreview: -1 // seconds; -1 = not seeking
    property int spTick: 0 // 500ms heartbeat while playing (slider motion)
    readonly property bool spAvailable: root.spStatus === "Playing" || root.spStatus === "Paused"
    // Interpolated position: the slider glides between 5s polls with no
    // per-second process spam.
    readonly property real spPosNow: {
        root.spTick;
        if (root.spStatus !== "Playing")
            return root.spPosBase;
        const est = root.spPosBase + (Date.now() - root.spPosAt) / 1000;
        return Math.max(0, root.spLength > 0 ? Math.min(est, root.spLength) : est);
    }

    function fmtTime(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    function parseSpMeta(text) {
        const lines = text.split("\n");
        const newTitle = (lines[0] || "").trim();
        const newArtist = (lines[1] || "").trim();
        // New track: restart the interpolated clock from 0 immediately
        // instead of showing the old song's position until the next
        // position poll lands.
        if ((newTitle !== root.spTitle || newArtist !== root.spArtist) && root.spSeekPreview < 0) {
            root.spPosBase = 0;
            root.spPosAt = Date.now();
        }
        root.spTitle = newTitle;
        root.spArtist = newArtist;
        const art = (lines[2] || "").trim();
        if (art !== root.spArtUrl)
            root.spArtUrl = art;
        const len = Math.floor(parseInt(lines[3] || "0", 10) / 1000000);
        root.spLength = isNaN(len) ? 0 : len;
    }

    function refreshSp() {
        if (!spMetaQuery.running)
            spMetaQuery.running = true;
        if (!spStatusQuery.running)
            spStatusQuery.running = true;
        if (!spPosQuery.running)
            spPosQuery.running = true;
    }

    function spCmd(action) {
        if (spCmdProc.running)
            return;
        spCmdProc.command = ["playerctl", "--player=spotify", action];
        spCmdProc.running = true;
    }

    function spSeek(secs) {
        if (spCmdProc.running)
            return;
        root.spPosBase = Math.max(0, root.spLength > 0 ? Math.min(secs, root.spLength) : secs);
        root.spPosAt = Date.now();
        spCmdProc.command = ["playerctl", "--player=spotify", "position", secs.toFixed(1)];
        spCmdProc.running = true;
    }

    Process {
        id: spMetaQuery
        command: ["playerctl", "--player=spotify", "metadata", "--format", "{{title}}\n{{artist}}\n{{mpris:artUrl}}\n{{mpris:length}}"]
        stdout: StdioCollector { onStreamFinished: root.parseSpMeta(text) }
        onExited: (code) => {
            if (code !== 0) {
                root.spStatus = "";
                root.spArtUrl = "";
            }
        }
    }
    Process {
        id: spStatusQuery
        command: ["playerctl", "--player=spotify", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim();
                root.spStatus = (s === "Playing" || s === "Paused") ? s : "";
            }
        }
        onExited: (code) => {
            if (code !== 0)
                root.spStatus = "";
        }
    }
    Process {
        id: spPosQuery
        command: ["playerctl", "--player=spotify", "position"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = parseFloat(text.trim());
                if (!isNaN(p)) {
                    root.spPosBase = Math.max(0, p);
                    root.spPosAt = Date.now();
                }
            }
        }
    }
    Process {
        id: spCmdProc
        onExited: root.refreshSp()
    }
    Timer {
        id: spPollTimer
        interval: 2000
        repeat: true
        running: root.open
        onTriggered: root.refreshSp()
    }
    Timer {
        id: spTickTimer
        interval: 500
        repeat: true
        running: root.open && root.spStatus === "Playing"
        onTriggered: root.spTick++
    }

    Process {
        id: uptimeQuery
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector { onStreamFinished: root.parseUptime(text) }
    }
    Timer {
        id: uptimeTimer
        interval: 60000
        repeat: true
        // Bound to open: zero wakeups/processes while the panel is closed.
        // triggeredOnStart covers the immediate refresh on open.
        running: root.open
        triggeredOnStart: true
        onTriggered: root.updateUptime()
    }

    // Stays true briefly after closing so the exit animation can
    // play out before the window hides.
    property bool closing: false
    onOpenChanged: {
        if (root.open) {
            root.closing = false;
            root.updateUptime();
            if (!ethQuery.running)
                ethQuery.running = true;
            if (!powerQuery.running)
                powerQuery.running = true;
            root.refreshSp();
        } else {
            root.closing = true;
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: 240 * root.animSpeed
        repeat: false
        onTriggered: root.closing = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: settingsWin
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            visible: root.open || root.closing
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-settings"
            exclusionMode: ExclusionMode.Ignore

            // Outside-click-to-close via focus grab: the first outside
            // click passes through to the app underneath and the grab
            // clearing closes us. Mask below limits input to the card.
            HyprlandFocusGrab {
                active: root.open
                windows: [settingsWin]
                onCleared: root.closeRequested()
            }

            mask: Region {
                Region { item: card }
            }

            Rectangle {
                id: card
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: root.topOffset
                    rightMargin: root.rightMargin
                }
                width: root.cardWidth
                height: layout.implicitHeight + 24
                radius: 14
                color: root.cBg
                border.color: root.cBorder
                border.width: 1

                // Simple GNOME-style pop: fade in while settling down a
                // few pixels. Exit mirrors via the closing state above.
                opacity: root.open ? 1 : 0
                Behavior on opacity { enabled: root.animSpeed > 0; NumberAnimation { duration: 180 * root.animSpeed; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: root.open ? 0 : -10
                    Behavior on y { enabled: root.animSpeed > 0; NumberAnimation { duration: 200 * root.animSpeed; easing.type: Easing.OutCubic } }
                }

                Column {
                    id: layout
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 8

                    // User header: face, greeting, uptime.
                    Row {
                        width: parent.width
                        spacing: 12

                        Item {
                            width: 56
                            height: 56
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: faceMask
                                anchors.fill: parent
                                radius: width / 2
                                visible: false
                            }
                            Image {
                                anchors.fill: parent
                                source: root.faceUrl
                                fillMode: Image.PreserveAspectCrop
                                layer.enabled: true
                                layer.effect: OpacityMask { maskSource: faceMask }
                                onStatusChanged: {
                                    if (status === Image.Error)
                                        root.hasFace = false;
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                visible: !root.hasFace
                                color: Qt.alpha(root.cBorder, 0.25)

                                Text {
                                    anchors.centerIn: parent
                                    text: root.userName.charAt(0).toUpperCase()
                                    font.family: "Inter"
                                    font.pixelSize: 22
                                    font.weight: Font.DemiBold
                                    color: root.cText
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.color: root.cBorder
                                border.width: 1
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 68
                            spacing: 2

                            Text {
                                width: parent.width
                                text: "Hello, " + root.userName
                                font.family: "Inter"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                color: root.cText
                                elide: Text.ElideRight
                                renderType: Text.QtRendering
                                antialiasing: true
                            }
                            Text {
                                width: parent.width
                                // U+F303: Nerd Font Arch Linux glyph.
                                text: " uptime, " + root.uptimeText
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                color: root.cMuted
                                elide: Text.ElideRight
                                renderType: Text.QtRendering
                                antialiasing: true
                            }
                        }
                    }

                    // Volume slider: full-rounded track, icon mutes.
                    // Drag previews locally; the value commits on release so
                    // a single drag sends one call through shell.qml.
                    Column {
                        width: parent.width
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 14
                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Volume"
                                font.family: "Inter"
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: root.cMuted
                                renderType: Text.QtRendering
                                antialiasing: true
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.muted ? "Muted" : Math.round((root.sliderPreview >= 0 ? root.sliderPreview : root.volume) * 100) + "%"
                                font.family: "Inter"
                                font.pixelSize: 12
                                color: root.cText
                                renderType: Text.QtRendering
                                antialiasing: true
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 24
                                horizontalAlignment: Text.AlignHCenter
                                text: root.muted || root.volume <= 0.001 ? "󰝟" : root.volume < 0.33 ? "󰕿" : root.volume < 0.66 ? "󰖀" : "󰕾"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                color: root.cText
                                renderType: Text.QtRendering
                                antialiasing: true

                                TapHandler { onTapped: root.muteToggled() }
                            }

                            Rectangle {
                                id: volTrack
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 32
                                height: 16
                                radius: 5
                                color: Qt.alpha(root.cBorder, 0.30)

                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: (root.sliderPreview >= 0 ? root.sliderPreview : Math.max(0, Math.min(1, root.volume))) * parent.width
                                    height: parent.height
                                    radius: 5
                                    color: root.muted ? Qt.alpha(root.cBorder, 0.55) : root.cBorder
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: (m) => { root.sliderPreview = ratio(m.x); }
                                    onPositionChanged: (m) => {
                                        if (pressed)
                                            root.sliderPreview = ratio(m.x);
                                    }
                                    onReleased: {
                                        if (root.sliderPreview >= 0) {
                                            root.volumeSetRequested(root.sliderPreview);
                                            root.sliderPreview = -1;
                                        }
                                    }
                                    onCanceled: root.sliderPreview = -1
                                    function ratio(x) { return Math.max(0, Math.min(1, x / volTrack.width)); }
                                }
                            }
                        }
                    }

                    // Shared space: ethernet (left) + power profile (right).
                    Row {
                        width: parent.width
                        visible: root.ethAvailable || root.powerAvailable
                        height: visible ? 56 : 0
                        spacing: 8

                        // Ethernet button.
                        Rectangle {
                            id: ethBtn
                            visible: root.ethAvailable
                            width: visible ? (parent.width - parent.spacing) / 2 : 0
                            height: 56
                            radius: 10
                            color: ethHover.hovered ? Qt.alpha(root.cBorder, 0.30) : Qt.alpha(root.cBorder, 0.15)
                            border.color: root.cBorder
                            border.width: 1
                            clip: true
                            Behavior on color { enabled: root.animSpeed > 0; ColorAnimation { duration: 120 * root.animSpeed } }

                            HoverHandler { id: ethHover }
                            TapHandler { onTapped: root.toggleEth() }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    width: ethBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    // U+F200: Nerd Font ethernet glyph.
                                    text: "󰈀"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: root.ethConnected ? root.cText : Qt.alpha(root.cText, 0.45)
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                                Text {
                                    width: ethBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.ethConnected ? "Ethernet · On" : "Ethernet · Off"
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: root.cText
                                    elide: Text.ElideRight
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                            }
                        }

                        // Power profile button: tap cycles Balanced →
                        // Performance → Power Saver.
                        Rectangle {
                            id: powerBtn
                            visible: root.powerAvailable
                            width: visible ? (parent.width - parent.spacing) / 2 : 0
                            height: 56
                            radius: 10
                            color: powerHover.hovered ? Qt.alpha(root.cBorder, 0.30) : Qt.alpha(root.cBorder, 0.15)
                            border.color: root.cBorder
                            border.width: 1
                            clip: true
                            Behavior on color { enabled: root.animSpeed > 0; ColorAnimation { duration: 120 * root.animSpeed } }

                            HoverHandler { id: powerHover }
                            TapHandler { onTapped: root.cyclePower() }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    width: powerBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.powerIcon
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: root.cText
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                                Text {
                                    width: powerBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.powerLabel
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: root.cText
                                    elide: Text.ElideRight
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                            }
                        }
                    }

                    // Power actions: sleep + shutdown.
                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            id: sleepBtn
                            width: (parent.width - parent.spacing) / 2
                            height: 56
                            radius: 10
                            color: sleepHover.hovered ? Qt.alpha(root.cBorder, 0.30) : Qt.alpha(root.cBorder, 0.15)
                            border.color: root.cBorder
                            border.width: 1
                            clip: true
                            Behavior on color { enabled: root.animSpeed > 0; ColorAnimation { duration: 120 * root.animSpeed } }

                            HoverHandler { id: sleepHover }
                            TapHandler { onTapped: Quickshell.execDetached(["systemctl", "suspend"]) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    width: sleepBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    // U+F186: Nerd Font moon glyph.
                                    text: "\uf186"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: root.cText
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                                Text {
                                    width: sleepBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Sleep"
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: root.cText
                                    elide: Text.ElideRight
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                            }
                        }

                        Rectangle {
                            id: shutBtn
                            width: (parent.width - parent.spacing) / 2
                            height: 56
                            radius: 10
                            color: shutHover.hovered ? Qt.alpha(root.cBorder, 0.30) : Qt.alpha(root.cBorder, 0.15)
                            border.color: root.cBorder
                            border.width: 1
                            clip: true
                            Behavior on color { enabled: root.animSpeed > 0; ColorAnimation { duration: 120 * root.animSpeed } }

                            HoverHandler { id: shutHover }
                            TapHandler { onTapped: Quickshell.execDetached(["systemctl", "poweroff"]) }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    width: shutBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    // U+F011: Nerd Font power glyph.
                                    text: "\uf011"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 18
                                    color: root.cText
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                                Text {
                                    width: shutBtn.width - 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Shut down"
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    color: root.cText
                                    elide: Text.ElideRight
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                            }
                        }
                    }

                    // Spotify center: art, title, artist, seek, transport.
                    // Hidden unless Spotify is running.
                    Column {
                        width: parent.width
                        visible: root.spAvailable
                        height: visible ? implicitHeight : 0
                        spacing: 6
                        clip: true

                        // Breathing room between the buttons row and Spotify.
                        Item { width: 1; height: 10 }

                        Item {
                            width: parent.width
                            height: 120

                            Rectangle {
                                anchors.centerIn: parent
                                width: 120
                                height: 120
                                radius: 12
                                color: Qt.alpha(root.cBorder, 0.15)

                                Rectangle {
                                    id: artMask
                                    anchors.fill: parent
                                    radius: 12
                                    visible: false
                                }
                                Image {
                                    anchors.fill: parent
                                    source: root.spArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                    layer.enabled: true
                                    layer.effect: OpacityMask { maskSource: artMask }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: root.spArtUrl === ""
                                    text: "♫"
                                    font.pixelSize: 40
                                    color: Qt.alpha(root.cText, 0.5)
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.spTitle !== "" ? root.spTitle : "Unknown title"
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            color: root.cText
                            elide: Text.ElideRight
                            renderType: Text.QtRendering
                            antialiasing: true
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: root.spArtist !== "" ? root.spArtist : "Unknown artist"
                            font.family: "Inter"
                            font.pixelSize: 12
                            color: root.cMuted
                            elide: Text.ElideRight
                            renderType: Text.QtRendering
                            antialiasing: true
                        }

                        Column {
                            width: parent.width
                            spacing: 2

                            Item {
                                width: parent.width
                                height: 14
                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.fmtTime(root.spSeekPreview >= 0 ? root.spSeekPreview : root.spPosNow)
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    color: root.cMuted
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.fmtTime(root.spLength)
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    color: root.cMuted
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }
                            }

                            Rectangle {
                                id: spTrack
                                width: parent.width
                                height: 12
                                radius: 5
                                color: Qt.alpha(root.cBorder, 0.30)

                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        verticalCenter: parent.verticalCenter
                                    }
                                    width: (root.spSeekPreview >= 0 ? root.spSeekPreview : (root.spLength > 0 ? root.spPosNow / root.spLength : 0)) * parent.width
                                    height: parent.height
                                    radius: 5
                                    color: root.cBorder
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: (m) => { root.spSeekPreview = ratio(m.x); }
                                    onPositionChanged: (m) => {
                                        if (pressed)
                                            root.spSeekPreview = ratio(m.x);
                                    }
                                    onReleased: {
                                        if (root.spSeekPreview >= 0) {
                                            root.spSeek(root.spSeekPreview);
                                            root.spSeekPreview = -1;
                                        }
                                    }
                                    onCanceled: root.spSeekPreview = -1
                                    function ratio(x) { return root.spLength > 0 ? Math.max(0, Math.min(1, x / spTrack.width)) * root.spLength : 0; }
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                horizontalAlignment: Text.AlignHCenter
                                text: "|◀"
                                font.pixelSize: 17
                                color: root.cText
                                renderType: Text.QtRendering
                                antialiasing: true

                                TapHandler { onTapped: root.spCmd("previous") }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                horizontalAlignment: Text.AlignHCenter
                                text: root.spStatus === "Playing" ? "❚❚" : "▶"
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                color: root.cText
                                renderType: Text.QtRendering
                                antialiasing: true

                                TapHandler { onTapped: root.spCmd("play-pause") }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 44
                                horizontalAlignment: Text.AlignHCenter
                                text: "▶|"
                                font.pixelSize: 17
                                color: root.cText
                                renderType: Text.QtRendering
                                antialiasing: true

                                TapHandler { onTapped: root.spCmd("next") }
                            }
                        }
                    }
                }
            }
        }
    }
}
