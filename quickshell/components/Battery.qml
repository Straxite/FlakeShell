import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

RowLayout {
    id: root
    spacing: 8

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: pill.isHovered ? 0 : 0
    anchors.horizontalCenterOffset: pill.isHovered ? 220 : 0
    opacity: pill.isHovered ? 1 : 0
    Behavior on opacity {
      NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    Behavior on anchors.horizontalCenterOffset {
      NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    property var battery: UPower.displayDevice
    property bool charging: battery.state === UPowerDeviceState.Charging
    readonly property int level: Math.round(battery.percentage * 100)

    readonly property string icon: {
        if(charging) return String.fromCodePoint(0xF0084)
        if(level >= 100) return String.fromCodePoint(0xF0079)
        if(level < 10) return String.fromCodePoint(0xF0083)

        return String.fromCodePoint(0xF007A + (Math.floor(level / 10) -1))
    }
Rectangle {
    color: "#1e1e2d"
    implicitHeight: 30
    implicitWidth: 60
    radius: 10
    anchors.centerIn: parent
    RowLayout {
    anchors.centerIn: parent
        Text {
            text: root.icon
            color: root.charging ? "#e8eaed"
                                 : root.level <= 15 ? "#ff5048"
                                 : root.level <= 30 ? "#ffa478"
                                 : "#e8eaed"
            font {
                family: "JetBrainsMono Nerd Font Propo"
                pixelSize: 18
            }
        }

        Text {
            text: root.level
            color: "#e8eaed"

            font {
                family: "Neue Machina"
                weight: 600
                pixelSize: 18
            }
            }
        }
    }
}
