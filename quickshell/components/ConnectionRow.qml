import QtQuick

// One row in the Wi-Fi / Bluetooth / audio lists: icon, title + subtitle, an action word
// ("Connect", "Selected", ...) and an optional little × (forget / remove).
FocusScope {
  id: root

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property int titleFontSize: 11
  property int subtitleFontSize: 9
  property int actionFontSize: 9
  property var active: false
  property bool busy: false
  property string actionText: ""
  property bool secondaryActionVisible: false
  property string secondaryActionName: ""
  signal clicked()
  signal secondaryClicked()

  activeFocusOnTab: true
  Keys.onReturnPressed: root.clicked()
  Keys.onEnterPressed: root.clicked()
  Keys.onSpacePressed: root.clicked()
  Accessible.role: Accessible.Button
  Accessible.name: title

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusSmall
    color: root.active ? Style.primaryContainer : (rowPointer.containsMouse ? Style.bg1 : "transparent")
    border.width: root.activeFocus ? 1 : 0
    border.color: Style.primary

    Behavior on color { ColorAnimation { duration: Style.animationFast } }
  }

  MouseArea {
    id: rowPointer
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  ShellText {
    id: iconText
    anchors.left: parent.left
    anchors.leftMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    width: 20
    text: root.icon
    color: root.active ? Style.primary : Style.muted
    font.pixelSize: 15
    horizontalAlignment: Text.AlignHCenter
  }

  Row {
    id: trailing
    anchors.right: parent.right
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 8

    ShellText {
      anchors.verticalCenter: parent.verticalCenter
      text: root.busy ? "…" : root.actionText
      color: root.active ? Style.primary : Style.muted
      font.pixelSize: root.actionFontSize
      font.weight: Font.DemiBold
    }

    Item {
      anchors.verticalCenter: parent.verticalCenter
      width: 20
      height: 20
      visible: root.secondaryActionVisible
      Accessible.role: Accessible.Button
      Accessible.name: root.secondaryActionName

      ShellText {
        anchors.centerIn: parent
        text: "×"
        color: secondaryPointer.containsMouse ? Style.red : Style.mutedDark
        font.pixelSize: 15
      }

      MouseArea {
        id: secondaryPointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.secondaryClicked()
      }
    }
  }

  Column {
    anchors.left: iconText.right
    anchors.leftMargin: 8
    anchors.right: trailing.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    spacing: 1

    ShellText {
      width: parent.width
      text: root.title
      elide: Text.ElideRight
      font.pixelSize: root.titleFontSize
      font.weight: Font.DemiBold
    }

    ShellText {
      width: parent.width
      text: root.subtitle
      color: Style.muted
      elide: Text.ElideRight
      font.pixelSize: root.subtitleFontSize
    }
  }
}
