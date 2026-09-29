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

  // FIX 1: this used to be `pill.rootTimer.running`, which failed because an `id`
  // is NOT a property of the object it lives in, so `pill.rootTimer` was undefined
  // and this stayed false forever. Now we go through `pill.rootTimer`, which is a
  // real property (an alias declared inside `pill` below) pointing at the Timer.
  // While the timer runs (1s after a workspace switch) the workspaces are shown.
  property bool showWorkspaces: pill.rootTimer.running

  color: "transparent"
  anchors { top: true; left: true; right: true }

  implicitHeight: pillHeight * 14
  margins { top: 10 }

  WlrLayershell.layer: WlrLayer.Top

  WlrLayershell.keyboardFocus: root.launcherActive
      ? WlrKeyboardFocus.OnDemand
      : WlrKeyboardFocus.None

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

  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() {
      pill.rootTimer.restart()
    }
  }

  Rectangle {
    id: pill

    // FIX 1 (other half): expose the Timer as a real property so `root` can reach it.
    // Without this alias, only code inside this Rectangle could see `rootTimer`.
    property alias rootTimer: rootTimer

    HoverHandler { id: hover }
    property bool isHovered: hover.hovered

    property bool isOpen: isHovered || root.launcherActive
    // (unused right now, safe to delete or use later)
    property bool isShowing: isHovered || root.showWorkspaces

    implicitHeight: {
      if (root.launcherActive && launcherLoader.item)
        return launcherLoader.item.implicitHeight + 20
      return isHovered ? root.pillHeight * 3 : root.pillHeight
    }
    implicitWidth: root.launcherActive ? root.pillHeight * 16
                : isHovered           ? root.pillHeight * 18
                : root.showWorkspaces           ? root.pillHeight * 4
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

    Timer {
      id: rootTimer
      interval: 1000
      running: false
      repeat: false
    }

    Loader {
      id: launcherLoader
      anchors.fill: parent
      anchors.margins: 10

      active: root.launcherActive
      sourceComponent: Launcher {}
    }
    Loader {
      id: wsLoader
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      active: root.showWorkspaces
      visible: root.showWorkspaces
      sourceComponent: Workspaces {}
      opacity: root.showWorkspaces ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
      }
    }

    Connections {
      target: launcherLoader.item
      function onCloseRequested() { root.launcherActive = false }
    }

    Clock { visible: !root.launcherActive && !root.showWorkspaces }
    Date { hovered: pill.isHovered; visible: !root.launcherActive && !root.showWorkspaces }
    Battery { visible: !root.launcherActive && !root.showWorkspaces }
  }
}
