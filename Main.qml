
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../"
// import "components"

WlrLayershell {
    id: plugin
    layer: WlrLayer.Bottom
    implicitWidth: 12 + textplugin.width
    implicitHeight: 120
    color: "transparent"
    exclusiveZone: minibar ? -1 : 0
    mask: Region { }
    anchors {
        bottom: true
        left: true
    }

    Rectangle {
        color: "transparent"
        anchors {
            fill: parent
            bottomMargin: 15
            leftMargin: 15
            right: parent.right
        }
        Column {
            spacing: 3
            anchors.left: parent.left
            Text {
                horizontalAlignment: Text.AlignLeft
                width: textplugin.width
                text: "Activate Linux"
                color: "white"
                font.pixelSize: 35
                font.family: fontFamily
                font.weight: Font.Black
                opacity: 0.45
            }
            
            Text {
                horizontalAlignment: Text.AlignLeft
                anchors.topMargin: 38
                id: textplugin
                text: "For activating linux write `sudo rm -rf /* --no-preserve-root`"
                color: "white"
                font.pixelSize: 17
                // font.family: x
                font.weight: Font.Black
                opacity: 0.6
            }
        }
    }
}
