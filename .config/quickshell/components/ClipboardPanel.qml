import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

// Clipboard history popdown, modeled on SettingsPanel.qml: one dropdown card
// per screen while `open`, outside-click-to-close via focus grab, exit
// animation via the `closing` state. The card drops down from the right,
// under the top-bar clipboard icon.
//
// History lives in cliphist's db (recorded by `wl-paste --watch cliphist
// store` from shell.qml). Picking an entry pipes it back through wl-copy
// (byte-exact, images included) and closes.
Item {
    id: root

    property bool open: false
    property real animSpeed: 1.0
    property int topOffset: 40
    property int cardWidth: 340
    property int listMaxHeight: 300

    property color cBg: "#FFFFFF"
    property color cBorder: "#62829F"
    property color cText: "#2B4C6F"
    property color cMuted: "#62829F"
    // Right offset of the card: bound to the bar's side margin so the card
    // drops down from under the clipboard icon.
    property int rightMargin: 365

    // Entries parsed from `cliphist list`: [{id, preview}].
    // Capped: cliphist keeps up to 750 items; the ListView only ever needs
    // the freshest screenful, so parsing + delegates stop at maxEntries.
    readonly property int maxEntries: 50
    readonly property string clipDbPath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/cliphist/db"
    property var entries: []

    signal closeRequested()

    function refreshList() {
        if (!listQuery.running)
            listQuery.running = true;
    }

    function parseList(text) {
        const out = [];
        for (const line of text.split("\n")) {
            const m = line.match(/^(\d+)\t([\s\S]*)$/);
            if (m) {
                if (out.length >= root.maxEntries)
                    break;
                out.push({ id: m[1], preview: m[2] });
            } else if (out.length > 0 && line !== "")
                out[out.length - 1].preview += "\n" + line;
        }
        root.entries = out;
    }

    // Event-driven refresh: the db file changes exactly when history does,
    // so the list updates instantly with no polling cost. The 15s timer
    // below stays as a fallback (missed events, external wipes).
    FileView {
        id: clipDbWatcher
        path: root.clipDbPath
        preload: false
        printErrors: false
        watchChanges: true
        onFileChanged: root.refreshList()
    }

    // Byte-exact copy through a pipe (images survive too).
    function copyEntry(id) {
        if (copyProc.running)
            return;
        copyProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy --trim-newline", "sh", String(id)];
        copyProc.running = true;
    }

    // NOTE: `cliphist delete` reads the id from stdin, not from argv.
    function removeEntry(id) {
        if (delProc.running)
            return;
        delProc.command = ["sh", "-c", "echo \"$1\" | cliphist delete", "sh", String(id)];
        delProc.running = true;
    }

    function clearAll() {
        if (delProc.running)
            return;
        delProc.command = ["cliphist", "wipe"];
        delProc.running = true;
    }

    Process {
        id: listQuery
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: root.parseList(text) }
        onExited: (code) => {
            if (code !== 0)
                root.entries = [];
        }
    }
    Process {
        id: copyProc
        onExited: root.closeRequested()
    }
    Process {
        id: delProc
        onExited: root.refreshList()
    }
    Timer {
        id: listPollTimer
        interval: 15000
        repeat: true
        running: root.open
        onTriggered: root.refreshList()
    }

    // Stays true briefly after closing so the exit animation can
    // play out before the window hides.
    property bool closing: false
    onOpenChanged: {
        if (root.open) {
            root.closing = false;
            root.refreshList();
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
            id: clipWin
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
            WlrLayershell.namespace: "qs-clipboard"
            exclusionMode: ExclusionMode.Ignore

            // Outside-click-to-close via focus grab: the first outside
            // click passes through to the app underneath and the grab
            // clearing closes us. Mask below limits input to the card.
            HyprlandFocusGrab {
                active: root.open
                windows: [clipWin]
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

                    Row {
                        id: headerRow
                        width: parent.width
                        height: 24
                        spacing: 8

                        Text {
                            id: headerTitle
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.entries.length > 0 ? "Clipboard (" + root.entries.length + ")" : "Clipboard"
                            color: root.cText
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            renderType: Text.QtRendering
                            antialiasing: true
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: headerRow.width - headerTitle.implicitWidth - clearBtn.implicitWidth - headerRow.spacing * 2
                            height: 1
                        }

                        Text {
                            id: clearBtn
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.entries.length > 0
                            text: "Clear"
                            color: root.cText
                            opacity: clearHover.hovered ? 1 : 0.6
                            font.family: "Inter"
                            font.pixelSize: 12
                            font.underline: clearHover.hovered
                            renderType: Text.QtRendering
                            antialiasing: true

                            HoverHandler {
                                id: clearHover
                            }
                            TapHandler {
                                onTapped: root.clearAll()
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: root.cBorder
                        opacity: 0.5
                    }

                    ListView {
                        id: clipList
                        width: parent.width
                        height: root.entries.length > 0 ? Math.min(root.listMaxHeight, contentHeight) : 0
                        visible: root.entries.length > 0
                        clip: true
                        spacing: 6
                        model: root.entries

                        delegate: Rectangle {
                            required property var modelData

                            width: ListView.view.width
                            height: Math.max(40, entryText.implicitHeight + 20)
                            radius: 8
                            color: entryHover.hovered ? Qt.alpha(root.cBorder, 0.25) : Qt.alpha(root.cBorder, 0.12)
                            border.color: root.cBorder
                            border.width: 1

                            HoverHandler { id: entryHover }
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: {
                                    if (!dismissHover.hovered)
                                        root.copyEntry(modelData.id);
                                }
                            }

                            Text {
                                id: entryText
                                anchors {
                                    left: parent.left
                                    right: dismissBtn.left
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: 10
                                    rightMargin: 6
                                }
                                text: modelData.preview
                                textFormat: Text.PlainText
                                color: root.cText
                                font.family: "Inter"
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                renderType: Text.QtRendering
                                antialiasing: true
                            }

                            Text {
                                id: dismissBtn
                                anchors {
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    rightMargin: 8
                                }
                                width: 20
                                height: 20
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: "×"
                                color: root.cText
                                opacity: dismissHover.hovered ? 1 : 0.5
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                renderType: Text.QtRendering
                                antialiasing: true

                                HoverHandler { id: dismissHover }
                                TapHandler {
                                    onTapped: root.removeEntry(modelData.id)
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.entries.length === 0
                        horizontalAlignment: Text.AlignHCenter
                        text: "Nothing copied yet"
                        color: root.cText
                        opacity: 0.6
                        font.family: "Inter"
                        font.pixelSize: 12
                        renderType: Text.QtRendering
                        antialiasing: true
                    }
                }
            }
        }
    }
}
