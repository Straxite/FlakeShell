import Quickshell
import QtQuick
import Quickshell.Hyprland
import QtQuick.Layouts

RowLayout {
    spacing: 8

    Repeater {
        model: 5

        Rectangle {
            id: wsButton
            required property int index

            property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
            property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)

            implicitWidth: label.implicitWidth + 14
            implicitHeight: 22
            radius: 6

            color: isActive ? "#80d4dc" : (ws ? "#533f5f" : "transparent")

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: wsButton.index + 1
                color: wsButton.isActive ? "#000000" : (wsButton.ws ? "#ffffff" : "#e8eaed")

                font {
                    family: "JetBrainsMono Nerd Font Propo"
                    letterSpacing: -1
                    pixelSize: 18
                    weight: 600
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (parent.index + 1) + " })")
            }
        }
    }
}
