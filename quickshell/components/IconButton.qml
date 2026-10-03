import QtQuick

// Square-ish button with a glyph. Anything you put inside it (e.g. an IconImage) is drawn on top.
FocusScope {
  id: root

  property string icon: ""
  property string accessibleName: ""
  property color foregroundColor: Style.foreground
  property color backgroundColor: "transparent"
  signal clicked()

  activeFocusOnTab: true
  opacity: enabled ? 1 : 0.4
  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()
  Accessible.role: Accessible.Button
  Accessible.name: accessibleName

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: pointer.containsMouse ? (root.backgroundColor.a > 0 ? Qt.lighter(root.backgroundColor, 1.15) : Style.bg1) : root.backgroundColor
    border.width: root.activeFocus ? 1 : 0
    border.color: Style.primary

    Behavior on color { ColorAnimation { duration: Style.animationFast } }
  }

  ShellText {
    anchors.centerIn: parent
    text: root.icon
    color: root.foregroundColor
    font.pixelSize: Math.round(Math.min(root.width, root.height) * 0.5)
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
