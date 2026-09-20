import QtQuick

// Rolling digit strip: shows 0-9 in a clipped column, slides `y` to the value.
Item {
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
        // Snap to whole pixels at rest so glyphs sit on the pixel grid (sharper).
        // During the roll animation y is fractional by design and briefly soft.
        y: digitRoot.active ? -digitRoot.value * Math.round(dummyText.implicitHeight) : 0

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
                height: Math.round(dummyText.implicitHeight)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // Grayscale GPU raster: no LCD subpixel fringe on transparent layer-shell.
                // NativeRendering assumes an opaque background and bleeds R/B subpixels
                // (yellow/blue glint) + pixelates when scaled/translated.
                renderType: Text.CurveRendering
                antialiasing: true
            }
        }
    }
}
