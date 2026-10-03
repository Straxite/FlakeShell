import QtQuick

// Quick-settings tile: click = toggle, the little arrow on the right = open its detail list.
FocusScope {
  id: root

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property var active: false          // var: callers pass things like `source && source.audio`
  property bool expandable: false
  property bool expanded: false
  property string detailAccessibleName: ""
  signal clicked()
  signal detailClicked()

  activeFocusOnTab: true
  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()
  Accessible.role: Accessible.Button
  Accessible.name: title

  Rectangle {
    anchors.fill: parent
    radius: Style.radius
    color: root.active ? Style.primaryContainer : (tilePointer.containsMouse ? Style.bg1 : Style.bg0)
    border.width: (root.activeFocus || root.expanded) ? 1 : 0
    border.color: Style.primary

    Behavior on color { ColorAnimation { duration: Style.animationFast } }
  }

  MouseArea {
    id: tilePointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  Row {
    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.right: chevron.visible ? chevron.left : parent.right
    anchors.rightMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    spacing: 10

    ShellText {
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      text: root.icon
      color: root.active ? Style.primary : Style.muted
      font.pixelSize: 16
      horizontalAlignment: Text.AlignHCenter
    }

    Column {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 30
      spacing: 1

      ShellText {
        width: parent.width
        text: root.title
        elide: Text.ElideRight
        font.pixelSize: 10
        font.weight: Font.Bold
      }

      ShellText {
        width: parent.width
        text: root.subtitle
        color: Style.muted
        elide: Text.ElideRight
        font.pixelSize: 9
      }
    }
  }

  Item {
    id: chevron

    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 26
    visible: root.expandable
    Accessible.role: Accessible.Button
    Accessible.name: root.detailAccessibleName

    ShellText {
      anchors.centerIn: parent
      text: "›"
      color: Style.muted
      font.pixelSize: 16
      rotation: root.expanded ? 90 : 0

      Behavior on rotation { NumberAnimation { duration: Style.animationFast } }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.detailClicked()
    }
  }
}
