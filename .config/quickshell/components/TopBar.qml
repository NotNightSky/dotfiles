import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland

// Top bar with clock that collapses into a small top-anchored island when apps open.
//   Empty workspace    -> full-width bar (reserves space, ExclusionMode.Auto).
//   Occupied workspace -> small centered tab flush with the top, over windows (Ignore).
// Click the island to stretch it from both sides into the full bar;
// click an empty spot of the expanded bar to shrink it back.
// The full bar carries a settings gear on the right.
// Occupied = focused Hyprland workspace has any toplevel (same definition
// the dock uses for hiding).
// Palette roles from color_palette_usage_guide.md:
//   bg     #FFFFFF white         (bar surface)
//   text   #2B4C6F Deep Denim    (body text, WCAG AAA on white)
//   border #62829F Dusty Slate   (Secondary -- borders/muted)
// Time is driven by shell.qml (shellRoot.currentTime) so there is exactly
// one ticker; currentTime defaults to now for standalone use.
Item {
    id: root

    property date currentTime: new Date()
    property bool use24Hour: false
    property color cBg: "#FFFFFF"
    property color cText: "#2B4C6F"
    property color cBorder: "#62829F"
    property int barHeight: 32
    property int islandHeight: 32
    property int barRadius: 10
    property int barSideMargin: 8
    property real animSpeed: 1.0

    // True when the focused workspace has any window on it.
    property bool appsOpen: false
    // True after clicking the island pill: temporarily show the full bar
    // over the open workspace. Click an empty spot to collapse back.
    property bool islandExpanded: false
    readonly property bool isIsland: root.appsOpen && !root.islandExpanded
    onAppsOpenChanged: if (!root.appsOpen)
        root.islandExpanded = false

    // Notifications toggle (state lives in shell.qml).
    property bool notifOpen: false
    property int notifCount: 0
    signal notifToggled()

    // Settings panel toggle (state lives in shell.qml).
    property bool settingsOpen: false
    signal settingsToggled()

    // Clipboard panel toggle (state lives in shell.qml).
    property bool clipOpen: false
    signal clipToggled()

    readonly property string islandText: Qt.formatDateTime(
        root.currentTime,
        root.use24Hour ? "HH:mm" : "hh:mm AP")

    function updateAppsOpen() {
        const wsId = Hyprland.focusedWorkspace?.id;
        if (wsId == null)
            return;
        for (const tl of Hyprland.toplevels.values) {
            if (tl.workspace?.id === wsId) {
                if (!root.appsOpen)
                    root.appsOpen = true;
                return;
            }
        }
        if (root.appsOpen)
            root.appsOpen = false;
    }

    readonly property int toplevelCount: Hyprland.toplevels.values.length
    onToplevelCountChanged: root.updateAppsOpen()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["workspace", "workspacev2", "activespecial",
                 "focusedmon", "focusedmonv2",
                 "openwindow", "closewindow",
                 "movewindow", "movewindowv2"].includes(event.name))
                root.updateAppsOpen();
        }
    }

    Component.onCompleted: root.updateAppsOpen()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            margins {
                top: 0
                left: root.barSideMargin
                right: root.barSideMargin
            }
            // Fixed to the taller mode so the window never resizes mid-morph;
            // the inner bar animates height within it.
            implicitHeight: Math.max(root.barHeight, root.islandHeight)

            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "qs-topbar"
            exclusionMode: root.appsOpen ? ExclusionMode.Ignore : ExclusionMode.Auto

            // Single morphing surface: the mask is always just this item,
            // so the window never eats clicks meant for apps underneath.
            mask: Region {
                Region { item: morphBar }
            }

            // ---- morphing bar: top-anchored tab <-> full bar ----
            // Centered + width-animated, so expanding grows from both sides.
            Rectangle {
                id: morphBar
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
                width: root.isIsland ? islandLabel.implicitWidth + 36 : parent.width
                height: root.isIsland ? root.islandHeight : root.barHeight
                color: root.cBg
                radius: root.isIsland ? height / 2 : root.barRadius
                border.color: root.cBorder
                border.width: 1
                Behavior on width { enabled: root.animSpeed > 0; NumberAnimation { duration: 280 * root.animSpeed; easing.type: Easing.OutCubic } }
                Behavior on height { enabled: root.animSpeed > 0; NumberAnimation { duration: 220 * root.animSpeed; easing.type: Easing.OutCubic } }
                Behavior on radius { enabled: root.animSpeed > 0; NumberAnimation { duration: 280 * root.animSpeed; easing.type: Easing.OutCubic } }

                // Square off the top corners (flush with screen top) in both
                // modes: patch over the top arcs, then restore the side outline.
                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                    height: parent.radius
                    color: root.cBg
                }
                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                    }
                    width: 1
                    height: parent.radius
                    color: root.cBorder
                }
                Rectangle {
                    anchors {
                        right: parent.right
                        top: parent.top
                    }
                    width: 1
                    height: parent.radius
                    color: root.cBorder
                }

                // Island click expands; empty-area click on the expanded bar
                // collapses. Clicks on the notification label / gear act
                // instead (guarded via hover so they never collapse).
                TapHandler {
                    onTapped: {
                        if (root.isIsland) {
                            root.islandExpanded = true;
                        } else if (root.appsOpen && root.islandExpanded && !notifHover.hovered && !settHover.hovered && !clipHover.hovered) {
                            root.islandExpanded = false;
                        }
                    }
                }
                // Island clock content.
                Text {
                    id: islandLabel
                    anchors.centerIn: parent
                    text: root.islandText
                    color: root.cText
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.3
                    renderType: Text.QtRendering
                    antialiasing: true
                    opacity: root.isIsland ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { enabled: root.animSpeed > 0; NumberAnimation { duration: 160 * root.animSpeed; easing.type: Easing.OutCubic } }
                }

                // Full-bar content.
                Text {
                    id: notifLabel
                    anchors.centerIn: parent
                    text: root.notifCount > 0 ? "Notifications (" + root.notifCount + ")" : (root.notifOpen ? "No new notifications" : "Notifications")
                    color: root.cText
                    font.family: "JetBrainsMono Nerd Font Mono"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.underline: notifHover.hovered
                    renderType: Text.QtRendering
                    antialiasing: true
                    opacity: root.isIsland ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { enabled: root.animSpeed > 0; NumberAnimation { duration: 160 * root.animSpeed; easing.type: Easing.OutCubic } }

                    HoverHandler {
                        id: notifHover
                    }
                    TapHandler {
                        onTapped: if (!root.isIsland)
                            root.notifToggled()
                    }
                }

                // ---- settings gear, right side (full bar only) ----
                Row {
                    id: quickRow
                    anchors {
                        right: parent.right
                        rightMargin: 12
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 4
                    opacity: root.isIsland ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { enabled: root.animSpeed > 0; NumberAnimation { duration: 160 * root.animSpeed; easing.type: Easing.OutCubic } }

                    // Clipboard: opens the history popdown.
                    Text {
                        id: clipBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        horizontalAlignment: Text.AlignHCenter
                        // U+F0EA: Nerd Font clipboard glyph.
                        text: "\uf0ea"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: root.cText
                        opacity: root.clipOpen || clipHover.hovered ? 1 : 0.75
                        renderType: Text.QtRendering
                        antialiasing: true

                        HoverHandler { id: clipHover }
                        TapHandler { onTapped: root.clipToggled() }
                    }

                    // Settings: opens the popdown panel.
                    Text {
                        id: settBtn
                        anchors.verticalCenter: parent.verticalCenter
                        width: 26
                        horizontalAlignment: Text.AlignHCenter
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: root.cText
                        opacity: root.settingsOpen || settHover.hovered ? 1 : 0.75
                        renderType: Text.QtRendering
                        antialiasing: true

                        HoverHandler { id: settHover }
                        TapHandler { onTapped: root.settingsToggled() }
                    }
                }
            }
        }
    }
}
