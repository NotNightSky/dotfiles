import QtQuick
import "./common"

// Stacked hours-over-minutes face.
Item {
    id: clockRoot

    property date currentTime: new Date()
    property bool use24Hour: false
    property int heroSize: 112
    property real animSpeed: 1.0
    property color cOnSurface
    property color cPrimary
    property color cPrimaryContainer
    property color cOnPrimaryContainer

    readonly property bool animated: animSpeed > 0
    readonly property string hoursText: Qt.formatDateTime(currentTime, use24Hour ? "HH" : "hh")
    readonly property string minutesText: Qt.formatDateTime(currentTime, "mm")
    readonly property string dateText: Qt.formatDateTime(currentTime, "ddd, MMM d")

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    // Properly sized (not 0x0 with centered content overflowing both sides),
    // so parents and PanelWindow measure exactly what is drawn.
    width: implicitWidth
    height: implicitHeight

    Column {
        id: content
        anchors.centerIn: parent
        spacing: -12

        Row {
            id: hoursRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -clockRoot.heroSize * 0.03

            property string text: clockRoot.hoursText
            onTextChanged: if (clockRoot.animated) bounceH.restart()

            Digit {
                digit: hoursRow.text.length > 0 ? hoursRow.text.charAt(0) : " "
                textColor: clockRoot.cOnSurface
                animationSpeed: clockRoot.animSpeed
                font.pixelSize: clockRoot.heroSize
                font.weight: Font.Black
                font.family: "Inter"
                font.letterSpacing: -clockRoot.heroSize * 0.025
            }
            Digit {
                digit: hoursRow.text.length > 1 ? hoursRow.text.charAt(1) : " "
                textColor: clockRoot.cOnSurface
                animationSpeed: clockRoot.animSpeed
                font.pixelSize: clockRoot.heroSize
                font.weight: Font.Black
                font.family: "Inter"
                font.letterSpacing: -clockRoot.heroSize * 0.025
            }

            SequentialAnimation {
                id: bounceH
                NumberAnimation { target: hoursRow; property: "scale"; to: 0.94; duration: 80 * clockRoot.animSpeed; easing.type: Easing.InQuad }
                NumberAnimation { target: hoursRow; property: "scale"; to: 1.0; duration: 350 * clockRoot.animSpeed; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
            }
        }

        Row {
            id: minutesRow
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: -clockRoot.heroSize * 0.03

            property string text: clockRoot.minutesText
            onTextChanged: if (clockRoot.animated) bounceM.restart()

            Digit {
                digit: minutesRow.text.length > 0 ? minutesRow.text.charAt(0) : " "
                textColor: clockRoot.cPrimary
                animationSpeed: clockRoot.animSpeed
                font.pixelSize: clockRoot.heroSize
                font.weight: Font.Black
                font.family: "Inter"
                font.letterSpacing: -clockRoot.heroSize * 0.025
            }
            Digit {
                digit: minutesRow.text.length > 1 ? minutesRow.text.charAt(1) : " "
                textColor: clockRoot.cPrimary
                animationSpeed: clockRoot.animSpeed
                font.pixelSize: clockRoot.heroSize
                font.weight: Font.Black
                font.family: "Inter"
                font.letterSpacing: -clockRoot.heroSize * 0.025
            }

            SequentialAnimation {
                id: bounceM
                NumberAnimation { target: minutesRow; property: "scale"; to: 0.94; duration: 80 * clockRoot.animSpeed; easing.type: Easing.InQuad }
                NumberAnimation { target: minutesRow; property: "scale"; to: 1.0; duration: 350 * clockRoot.animSpeed; easing.type: Easing.OutBack; easing.overshoot: 0.6 }
            }
        }

        Item { width: 1; height: 20 }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: dateLabel.implicitWidth + 32
            height: 34
            radius: 17
            color: clockRoot.cPrimaryContainer
            antialiasing: true

            Text {
                id: dateLabel
                anchors.centerIn: parent
                text: clockRoot.dateText
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: "Inter"
                font.letterSpacing: 0.3
                color: clockRoot.cOnPrimaryContainer
                // Same reason as digits: avoid LCD subpixel fringe on transparency.
                renderType: Text.QtRendering
                antialiasing: true
            }
        }
    }
}
