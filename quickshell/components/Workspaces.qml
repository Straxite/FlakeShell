import Quickshell
import QtQuick
import Quickshell.Hyprland

Item {
    // Hyprland.focusedWorkspace is null for a split second at startup, hence the ?.
    // and the fallback of "?" so it never throws an error.
    property string wsId: Hyprland.focusedWorkspace?.id ?? "?"

    Text {
        // Loader in Pill.qml uses anchors.fill, so this Item fills the pill
        // and the text just sits in the middle of it.
        anchors.centerIn: parent

        // Want just the number? Change this to: text: parent.wsId
        text: "Workspace " + parent.wsId
        color: "#ffffff"
        Behavior on text {
          NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        font {
            family: "SF Pro Display"
            letterSpacing: -1
            pixelSize: 18
            weight: 500
        }
    }
}

