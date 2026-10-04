import QtQuick

// Content-only brightness display for the pill. Pill.qml owns the state and passes it in.
Row {
    property real level: 0

    spacing: 10

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: level < 0.33 ? "󰃞" : level < 0.66 ? "󰃟" : "󰃠"
        color: "white"
        font.pixelSize: 16
        font.family: "Symbols Nerd Font"
    }

    // track
    Item {
        width: 260; height: 4
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: 2
            color: "#55ffffff"
        }
        Rectangle {
            width: parent.width * Math.min(level, 1)
            height: parent.height
            radius: 2
            color: "white"
            Behavior on width { NumberAnimation { duration: 80 } }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(level * 100)
        color: "white"
        font.pixelSize: 13
    }
}
