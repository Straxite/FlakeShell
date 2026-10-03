import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
  id: root

  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Top

  property bool active: false

  visible: active

  WlrLayershell.keyboardFocus: active
      ? WlrKeyboardFocus.OnDemand
      : WlrKeyboardFocus.None

  HyprlandFocusGrab {
    windows: [root]
    active: root.active
    onCleared: root.active = false
  }

  IpcHandler {
    target: "controlpanel"

    function toggle(): void {
      root.active = !root.active
    }
  }

  Loader {
    id: panelLoader

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: 30

    width: 492
    height: item ? item.implicitHeight : 0

    active: root.active
    source: "ControlPanel.qml"

    onLoaded: {
      if (item) {
        item.width = 492
        item.height = item.implicitHeight
      }
    }
  }

  // Make the rest of the screen click-through.
  mask: Region {
    item: panelLoader.item
  }
}
