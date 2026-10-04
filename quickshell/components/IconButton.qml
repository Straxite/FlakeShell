import QtQuick
import qs

FocusScope {
    id: root

    property string icon: ""
    property string accessibleName: ""
    property color backgroundColor: Colors.onSurface
    property color foregroundColor: Colors.primary
    property color hoverBackgroundColor: Colors.primaryContainer
    property color hoverForegroundColor: Colors.primary
    readonly property bool hovered: pointer.containsMouse

    signal clicked()

    implicitWidth: 32
    implicitHeight: 32
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    scale: hovered ? 1.06 : 1

    Behavior on scale {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.activeFocus || root.hovered ? root.hoverBackgroundColor : root.backgroundColor
        border.width: root.activeFocus ? 2 : 0
        border.color: Colors.primary

        Behavior on color {
            ColorAnimation {
                duration: 150
            }

        }

    }

    ShellText {
        anchors.centerIn: parent
        text: root.icon
        color: root.hovered ? root.hoverForegroundColor : root.foregroundColor
        font.pixelSize: 15
        font.weight: Font.DemiBold

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: pointer

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

}
