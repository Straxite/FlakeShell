import QtQuick

// Horizontal slider. `value` is 0..1 and comes from outside; dragging only emits moved(value),
// the owner decides what to do with it (set volume, brightness, ...).
FocusScope {
  id: root

  property bool filled: true
  property string icon: ""
  property string accessibleName: ""
  property real value: 0
  property string valueText: ""
  signal moved(real value)

  // while dragging show the finger position, otherwise the real value
  property real dragValue: 0
  readonly property real shown: dragArea.pressed ? dragValue : Math.max(0, Math.min(1, value))

  implicitHeight: 36
  activeFocusOnTab: true
  Accessible.role: Accessible.Slider
  Accessible.name: accessibleName
  Keys.onLeftPressed: root.moved(Math.max(0, root.value - 0.05))
  Keys.onRightPressed: root.moved(Math.min(1, root.value + 0.05))

  Rectangle {
    id: track
    anchors.fill: parent
    radius: Style.radius
    color: Style.bg1
    border.width: root.activeFocus ? 1 : 0
    border.color: Style.primary

    // the filled part: never narrower than the height, so the icon always sits on a round end
    Rectangle {
      width: track.height + (track.width - track.height) * root.shown
      height: track.height
      radius: track.radius
      color: Style.primary
      visible: root.filled
    }

    ShellText {
      anchors.left: parent.left
      anchors.leftMargin: (track.height - width) / 2
      anchors.verticalCenter: parent.verticalCenter
      text: root.icon
      color: Style.bgDim
      font.pixelSize: 14
    }

    ShellText {
      anchors.right: parent.right
      anchors.rightMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      visible: text.length > 0
      text: root.valueText
      color: root.shown > 0.88 ? Style.bgDim : Style.foreground
      font.pixelSize: 10
      font.weight: Font.DemiBold
    }
  }

  MouseArea {
    id: dragArea

    function setFrom(x) {
      const span = Math.max(1, root.width - root.height);
      root.dragValue = Math.max(0, Math.min(1, (x - root.height / 2) / span));
      root.moved(root.dragValue);
    }

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onPressed: (mouse) => setFrom(mouse.x)
    onPositionChanged: (mouse) => { if (pressed) setFrom(mouse.x); }
  }
}
