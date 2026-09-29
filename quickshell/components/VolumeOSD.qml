import QtQuick

// Content-only volume display for the pill. Pill.qml owns the state and passes it in.
Row {
    property real vol: 0
    property bool muted: false

    spacing: 10

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: muted || vol === 0 ? "󰝟" : vol < 0.5 ? "󰖀" : "󰕾"
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
            width: parent.width * Math.min(vol, 1)
            height: parent.height
            radius: 2
            color: muted ? "#88ffffff" : "white"
            Behavior on width { NumberAnimation { duration: 80 } }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(vol * 100)
        color: "white"
        font.pixelSize: 13
    }
}
