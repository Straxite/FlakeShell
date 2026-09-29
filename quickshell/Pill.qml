import Quickshell
import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import "./components"

PanelWindow {
  id: root

  property int pillHeight: 30
  property int radius: 16
  property color bg1: "#000000"

  // LAUNCHER: the one on/off switch. The keybind flips it, Escape/launching an app clears it.
  property bool launcherActive: false

  color: "transparent"
  anchors { top: true; left: true; right: true }

  // LAUNCHER: window is now tall enough to fit the biggest launcher list.
  // It's transparent and `mask` below limits clicks to the pill, so you won't notice.
  // (Kept constant on purpose: resizing the window every frame would jitter.)
  implicitHeight: pillHeight * 14
  margins { top: 10 }

  WlrLayershell.layer: WlrLayer.Top

  // LAUNCHER: lets the search box receive keystrokes while the launcher is open.
  // OnDemand (not Exclusive) so it can never lock your keyboard/mouse out.
  WlrLayershell.keyboardFocus: root.launcherActive
      ? WlrKeyboardFocus.OnDemand
      : WlrKeyboardFocus.None

  // LAUNCHER: Hyprland-side focus. Gives the launcher keyboard focus when it opens
  // and closes it when you click anywhere outside the pill, so you can't get stuck.
  HyprlandFocusGrab {
    windows: [ root ]
    active: root.launcherActive
    onCleared: root.launcherActive = false
  }

  exclusiveZone: pillHeight

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      root.launcherActive = !root.launcherActive
    }
  }

  mask: Region {
    item: pill
  }

  Rectangle {
    id: pill

    HoverHandler { id: hover }
    property bool isHovered: hover.hovered

    property bool isOpen: isHovered || root.launcherActive

    implicitHeight: {
      if (root.launcherActive && launcherLoader.item)
        return launcherLoader.item.implicitHeight + 20
      return isHovered ? root.pillHeight * 3 : root.pillHeight
    }
    implicitWidth: root.launcherActive ? root.pillHeight * 16
                : isHovered           ? root.pillHeight * 18
                :                       root.pillHeight * 3

    radius: isOpen ? root.radius * 2 : root.radius

    Behavior on radius {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    color: root.bg1

    // Aligns to the top center so expansion happens downward and outwards
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    Behavior on implicitHeight {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Behavior on implicitWidth {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Loader {
      id: launcherLoader
      anchors.fill: parent
      anchors.margins: 10

      active: root.launcherActive
      sourceComponent: Launcher {}
    }

    Connections {
      target: launcherLoader.item
      function onCloseRequested() { root.launcherActive = false }
    }

    Clock { visible: !root.launcherActive }
    Date { hovered: pill.isHovered; visible: !root.launcherActive }
    Battery { visible: !root.launcherActive }
  }
}
