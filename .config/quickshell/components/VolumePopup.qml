import QtQuick

// Compact volume OSD pill: icon on the left, horizontal bar that
// fills/drains with volume. Dumb visual -- volume state + show/hide
// logic lives in shell.qml (Pipewire binding).
Rectangle {
    id: popup

    property real volume: 0.0 // 0.0..1.0+ (bar clamps at 1.0)
    property bool muted: false
    property real animSpeed: 1.0 // 0 disables motion

    property color cOnSurface: "#2B4C6F"
    property color cPrimary: "#A7CBEB"
    property color cTrack: "#62829F"
    property color cMuted: "#62829F"

    readonly property real clamped: Math.max(0, Math.min(1, volume))
    // Nerd Font speaker glyphs: off / low / medium / high
    readonly property string iconText: {
        if (muted || volume <= 0.001)
            return "󰝟";
        if (volume < 0.33)
            return "󰕿";
        if (volume < 0.66)
            return "󰖀";
        return "󰕾";
    }
    readonly property string pctText: muted ? "Muted" : Math.round(volume * 100) + "%"

    implicitWidth: 320
    implicitHeight: 68
    radius: 16
    color: "#F8FAF9"
    border.color: cTrack
    border.width: 1
    antialiasing: true

    Row {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 14

        Text {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            text: popup.iconText
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            color: popup.muted ? popup.cMuted : popup.cOnSurface
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            renderType: Text.QtRendering
            antialiasing: true
        }

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: 170
            height: 8
            radius: 4
            color: popup.cTrack
            opacity: 0.55
            antialiasing: true
            clip: true

            Rectangle {
                id: fill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: popup.clamped * track.width
                height: parent.height
                radius: 4
                color: popup.muted ? popup.cMuted : popup.cPrimary
                antialiasing: true

                Behavior on width {
                    enabled: popup.animSpeed > 0
                    NumberAnimation {
                        duration: 120 * popup.animSpeed
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    enabled: popup.animSpeed > 0
                    ColorAnimation {
                        duration: 150 * popup.animSpeed
                    }
                }
            }
        }

        Text {
            id: pct
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            text: popup.pctText
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.Bold
            color: popup.muted ? popup.cMuted : popup.cOnSurface
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            renderType: Text.QtRendering
            antialiasing: true
        }
    }
}
