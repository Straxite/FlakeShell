import QtQuick
import QtQuick.Layouts
import Quickshell
import qs

// First-level menu: Wallpaper / Theme.
// Picking a row just calls that row's IPC target (`qs ipc call <target> toggle`).
// Pill.qml's IpcHandlers do the actual opening/closing of the other menus.
Item {
  id: root

  readonly property int rowHeight: 46
  readonly property int rowSpacing: 4

  // name = what's shown, target = IPC target that gets toggled
  readonly property var options: [
    { name: "Wallpaper", target: "wallpaper" },
    { name: "Theme",     target: "theme" }
  ]

  implicitWidth: 480
  implicitHeight: options.length * rowHeight + (options.length - 1) * rowSpacing

  signal closeRequested()

  function choose(target) {
    // execDetached keeps running even though this menu is about to be destroyed
    Quickshell.execDetached(["qs", "ipc", "call", target, "toggle"])
  }

  // fade in after the pill has finished resizing (same trick as the launcher)
  opacity: 0
  Behavior on opacity {
    NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
  }
  Timer {
    interval: 120
    running: true
    repeat: false
    onTriggered: root.opacity = 1
  }

  // keyboard: up/down/enter/esc
  focus: true
  Keys.onEscapePressed: root.closeRequested()
  Keys.onReturnPressed: root.choose(root.options[list.currentIndex].target)
  Keys.onDownPressed: list.incrementCurrentIndex()
  Keys.onUpPressed: list.decrementCurrentIndex()

  ListView {
    id: list
    anchors.fill: parent
    clip: true
    spacing: root.rowSpacing
    model: root.options
    currentIndex: 0
    highlightMoveDuration: 100
    interactive: false

    delegate: Rectangle {
      id: entry
      required property var modelData
      required property int index

      width: list.width
      implicitHeight: root.rowHeight
      radius: 12
      color: list.currentIndex === index ? "#313036" : "transparent"

      Behavior on color {
        ColorAnimation { duration: 100 }
      }

      // little accent bar on the selected row
      Rectangle {
        implicitWidth: list.currentIndex === entry.index ? 4 : 0
        implicitHeight: list.currentIndex === entry.index ? 20 : 0
        anchors.verticalCenter: parent.verticalCenter
        color: Colors.primary
        radius: 16

        Behavior on implicitWidth {
          NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
        Behavior on implicitHeight {
          NumberAnimation { duration: 100 }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 20
        text: entry.modelData.name
        color: "#e8eaed"
        font {
          family: "SF Pro Display"
          pixelSize: 14
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: list.currentIndex = entry.index
        onClicked: root.choose(entry.modelData.target)
      }
    }
  }

  Component.onCompleted: root.forceActiveFocus()
}
