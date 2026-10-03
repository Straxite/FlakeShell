import QtQuick

Item {
  id: root

  property string title: ""
  property bool showCloseButton: true
  signal closeRequested()

  width: parent ? parent.width : implicitWidth
  implicitHeight: 28

  ShellText {
    anchors.verticalCenter: parent.verticalCenter
    text: root.title
    font.pixelSize: 14
    font.weight: Font.Bold
  }

  IconButton {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    width: 24
    height: 24
    visible: root.showCloseButton
    icon: "×"
    accessibleName: "Close"
    onClicked: root.closeRequested()
  }
}
