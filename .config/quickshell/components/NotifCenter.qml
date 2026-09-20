import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// Notification center dropdown. Owns the single NotificationServer (takes
// over org.freedesktop.Notifications -- dunst must stay off) and shows one
// dropdown card per screen while `open`.
Item {
    id: root

    property bool open: false
    property color cBg: "#FFFFFF"
    property color cCard: "#A7CBEB"
    property color cText: "#2B4C6F"
    property color cBorder: "#62829F"
    property color cAccent: "#EBAA9D"
    property string fontFamily: "JetBrainsMono Nerd Font Mono"
    property real animSpeed: 1.0
    property int cardWidth: 380
    property int listMaxHeight: 320
    // Gap between the bar and the floating card (GNOME-style popdown).
    property int topOffset: 40

    readonly property int count: server.trackedNotifications.values.length

    signal closeRequested()

    // Stays true briefly after closing so the exit animation can
    // play out before the window hides.
    property bool closing: false
    onOpenChanged: {
        if (root.open)
            root.closing = false;
        else {
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

    NotificationServer {
        id: server
        actionsSupported: true
        persistenceSupported: true
        onNotification: notif => {
            notif.tracked = true;
        }
    }

    function clearAll() {
        // Copy: dismiss() mutates the model during iteration.
        const items = server.trackedNotifications.values.slice();
        for (const n of items)
            n.dismiss();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: notifWin
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
            WlrLayershell.namespace: "qs-notif-center"
            exclusionMode: ExclusionMode.Ignore

            // Outside-click-to-close via focus grab: the first outside
            // click passes through to the app underneath and the grab
            // clearing closes us. Mask below limits input to the card.
            HyprlandFocusGrab {
                active: root.open
                windows: [notifWin]
                onCleared: root.closeRequested()
            }

            mask: Region {
                Region { item: card }
            }

            Rectangle {
                id: card
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: root.topOffset
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
                Behavior on opacity { NumberAnimation { duration: 180 * root.animSpeed; easing.type: Easing.OutCubic } }
                transform: Translate {
                    y: root.open ? 0 : -10
                    Behavior on y { NumberAnimation { duration: 200 * root.animSpeed; easing.type: Easing.OutCubic } }
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
                            text: root.count > 0 ? "Notifications (" + root.count + ")" : "Notifications"
                            color: root.cText
                            font.family: root.fontFamily
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
                            visible: root.count > 0
                            text: "Clear all"
                            color: root.cText
                            opacity: clearHover.hovered ? 1 : 0.6
                            font.family: root.fontFamily
                            font.pixelSize: 12
                            font.underline: clearHover.hovered
                            renderType: Text.QtRendering
                            antialiasing: true

                            HoverHandler {
                                id: clearHover
                                cursorShape: Qt.PointingHandCursor
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
                        id: notifList
                        width: parent.width
                        height: root.count > 0 ? Math.min(root.listMaxHeight, contentHeight) : 0
                        visible: root.count > 0
                        clip: true
                        spacing: 8
                        model: server.trackedNotifications

                        delegate: Rectangle {
                            required property var modelData
                            readonly property var notif: modelData

                            width: ListView.view.width
                            height: delegateCol.implicitHeight + 20
                            radius: 10
                            color: notif.urgency === NotificationUrgency.Critical ? root.cAccent : root.cCard
                            border.color: root.cBorder
                            border.width: 1

                            Column {
                                id: delegateCol
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: 10
                                }
                                spacing: 4

                                Row {
                                    width: parent.width
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - dismissBtn.width - parent.spacing
                                        text: notif.appName
                                        color: root.cText
                                        opacity: 0.7
                                        font.family: root.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        renderType: Text.QtRendering
                                        antialiasing: true
                                    }

                                    Text {
                                        id: dismissBtn
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 20
                                        height: 20
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        text: "×"
                                        color: root.cText
                                        opacity: dismissHover.hovered ? 1 : 0.6
                                        font.family: root.fontFamily
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        renderType: Text.QtRendering
                                        antialiasing: true

                                        HoverHandler {
                                            id: dismissHover
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                        TapHandler {
                                            onTapped: notif.dismiss()
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: notif.summary
                                    color: root.cText
                                    font.family: root.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }

                                Text {
                                    width: parent.width
                                    visible: notif.body !== ""
                                    text: notif.body
                                    color: root.cText
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                    renderType: Text.QtRendering
                                    antialiasing: true
                                }

                                Row {
                                    visible: notif.actions.length > 0
                                    spacing: 6

                                    Repeater {
                                        model: notif.actions

                                        Rectangle {
                                            required property var modelData
                                            width: actionLabel.implicitWidth + 20
                                            height: 24
                                            radius: 12
                                            color: "transparent"
                                            border.color: root.cBorder
                                            border.width: 1

                                            Text {
                                                id: actionLabel
                                                anchors.centerIn: parent
                                                text: parent.modelData.text
                                                color: root.cText
                                                font.family: root.fontFamily
                                                font.pixelSize: 12
                                                renderType: Text.QtRendering
                                                antialiasing: true
                                            }

                                            HoverHandler {
                                                cursorShape: Qt.PointingHandCursor
                                            }
                                            TapHandler {
                                                onTapped: parent.modelData.invoke()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        text: "No new notifications"
                        color: root.cText
                        opacity: 0.6
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        renderType: Text.QtRendering
                        antialiasing: true
                    }
                }
            }
        }
    }
}