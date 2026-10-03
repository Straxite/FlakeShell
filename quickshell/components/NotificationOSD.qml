import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: item
    property var notif: null
    signal clicked()

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Image {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            Layout.alignment: Qt.AlignVCenter
            visible: source != ""
            fillMode: Image.PreserveAspectFit
            sourceSize: Qt.size(36, 36)
            source: {
                if (!item.notif) return ""
                if (item.notif.image !== "") return item.notif.image
                if (item.notif.appIcon !== "") return Quickshell.iconPath(item.notif.appIcon, true)
                return ""
            }
        }

        Text {
            Layout.maximumWidth: 160
            Layout.alignment: Qt.AlignVCenter
            text: item.notif?.summary ?? ""
            color: "white"
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: item.notif?.body ?? ""
            color: "#bbffffff"
            font.pixelSize: 13
            elide: Text.ElideRight
            maximumLineCount: 1
            textFormat: Text.PlainText
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: item.clicked()
    }
}
