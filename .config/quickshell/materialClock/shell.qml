//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland

// m3qs mono build: config + palette + clock face in one file.
// Edit the `config` / `palette` blocks below to tweak.

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

    // ---- palette: nordic-slate roles actually used (was Colors.qml) ----
    // NOTE: no `onX` names -- QML reserves on+Uppercase for signal handlers.
    readonly property color cOnSurface: "#E0E4E8"
    readonly property color cPrimary: "#8EADC8"
    readonly property color cPrimaryContainer: "#34506A"
    readonly property color cOnPrimaryContainer: "#D0E8FF"

    // ---- rolling digit strip (was components/common/Digit.qml) ----
    component Digit: Item {
        id: digitRoot

        property string digit: "0"
        property color textColor
        property font font
        property real animationSpeed: 1.0

        readonly property bool animated: animationSpeed > 0
        readonly property int value: (digit >= "0" && digit <= "9") ? parseInt(digit) : -1
        readonly property bool active: value !== -1

        width: active ? activeText.implicitWidth : 0
        opacity: active ? 1.0 : 0.0
        implicitWidth: activeText.implicitWidth
        implicitHeight: dummyText.implicitHeight
        clip: true

        Behavior on width {
            enabled: digitRoot.animated
            NumberAnimation {
                duration: 350 * digitRoot.animationSpeed
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            enabled: digitRoot.animated
            NumberAnimation {
                duration: 250 * digitRoot.animationSpeed
            }
        }

        Text {
            id: dummyText
            text: "0"
            font: digitRoot.font
            visible: false
        }

        Text {
            id: activeText
            text: digitRoot.digit
            font: digitRoot.font
            visible: false
        }

        Column {
            width: parent.width
            y: digitRoot.active ? -digitRoot.value * dummyText.implicitHeight : 0

            Behavior on y {
                enabled: digitRoot.animated
                NumberAnimation {
                    duration: 450 * digitRoot.animationSpeed
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.05
                }
            }

            Repeater {
                model: 10
                Text {
                    text: index.toString()
                    font: digitRoot.font
                    color: digitRoot.textColor
                    width: parent.width
                    height: dummyText.implicitHeight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // ---- stacked hours-over-minutes face (was components/StackedDigitalClock.qml) ----
    component StackedClock: Item {
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
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
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

            // Minute granularity: the face shows no seconds, so only assign
            // on wall-clock minute rollover instead of churning every second.
            property date currentTime: new Date()
            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    var now = new Date()
                    if (Math.floor(now.getTime() / 60000) !== Math.floor(root.currentTime.getTime() / 60000))
                        root.currentTime = now
                }
            }

            StackedClock {
                id: clock
                anchors.centerIn: parent
                currentTime: root.currentTime
                use24Hour: shellRoot.use24Hour
                heroSize: shellRoot.heroFontSize
                animSpeed: shellRoot.animationSpeed
                cOnSurface: shellRoot.cOnSurface
                cPrimary: shellRoot.cPrimary
                cPrimaryContainer: shellRoot.cPrimaryContainer
                cOnPrimaryContainer: shellRoot.cOnPrimaryContainer
            }
        }
    }
}
