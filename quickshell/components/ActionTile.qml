import QtQuick
import qs

FocusScope {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool expandable: false
    property bool expanded: false
    property string detailAccessibleName: "Show " + title + " options"

    signal clicked()
    signal detailClicked()

    implicitHeight: 58
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: title + (subtitle ? ", " + subtitle : "")

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.active ? Colors.primary : Colors.surface
        border.width: root.activeFocus || detailButton.activeFocus ? 2 : 0
        border.color: Colors.primary

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    Row {
        anchors.left: parent.left
        anchors.right: detailButton.visible ? detailButton.left : parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 9
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: 15
            color: root.active ? Qt.rgba(0.12, 0.14, 0.12, 0.14) : Colors.surfaceContainerHigh

            ShellText {
                anchors.centerIn: parent
                text: root.icon
                color: root.active ? Colors.surfaceContainerLowest : Colors.onSurface
                font.pixelSize: 14
                font.weight: Font.Bold
            }

        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 38
            spacing: 2

            ShellText {
                width: parent.width
                text: root.title
                color: root.active ? Colors.surfaceContainerLowest : Colors.outline
                elide: Text.ElideRight
                font.pixelSize: 12
                font.weight: Font.Bold
            }

            ShellText {
                width: parent.width
                text: root.subtitle
                color: root.active ? Qt.rgba(0.12, 0.14, 0.12, 0.68) : Colors.outline
                elide: Text.ElideRight
                font.pixelSize: 9
            }

        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: detailButton.visible ? detailButton.left : parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    FocusScope {
        id: detailButton

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.expandable ? 31 : 0
        visible: root.expandable
        activeFocusOnTab: visible
        Keys.onReturnPressed: root.detailClicked()
        Keys.onEnterPressed: root.detailClicked()
        Keys.onSpacePressed: root.detailClicked()
        Accessible.role: Accessible.Button
        Accessible.name: root.detailAccessibleName

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height - 18
            color: root.active ? Qt.rgba(0.12, 0.14, 0.12, 0.18) : Colors.outline
        }

        ShellText {
            anchors.centerIn: parent
            text: root.expanded ? "󰅃" : "󰅀"
            color: root.active ? Qt.rgba(0.12, 0.14, 0.12, 0.62) : Colors.outline
            font.pixelSize: 11
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.detailClicked()
        }

    }

}
