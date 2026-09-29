import Quickshell
import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
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

  // VOLUME: pill shows the volume bar for 1.5s after any volume/mute change.
  readonly property var sink: Pipewire.defaultAudioSink
  readonly property real vol: sink?.audio?.volume ?? 0
  readonly property bool muted: sink?.audio?.muted ?? false
  property bool showVolume: false

  PwObjectTracker { objects: [root.sink] }

  Connections {
    target: root.sink?.audio ?? null
    function onVolumeChanged() { root.pokeVolume() }
    function onMutedChanged()  { root.pokeVolume() }
  }

  function pokeVolume() {
    if (launcherActive) return
    showBrightness = false
    showVolume = true
    volumeTimer.restart()
  }

  Timer {
    id: volumeTimer
    interval: 1500
    onTriggered: root.showVolume = false
  }

  // BRIGHTNESS: same idea. Polls brightnessctl and pops the pill when the value changes.
  property real brightness: 0
  property bool brightnessReady: false
  property bool showBrightness: false

  Process {
    id: brightnessProc
    command: ["brightnessctl", "-m"]
    stdout: SplitParser {
      onRead: data => root.updateBrightness(data)
    }
  }

  Timer {
    interval: 250
    running: true
    repeat: true
    onTriggered: if (!brightnessProc.running) brightnessProc.running = true
  }

  // brightnessctl -m prints: device,class,current,percent%,max
  function updateBrightness(line) {
    const pct = parseInt(line.split(",")[3]) / 100
    if (isNaN(pct)) return
    // first read just sets the baseline, so no popup at startup
    if (brightnessReady && pct !== brightness && !launcherActive) {
      showVolume = false
      showBrightness = true
      brightnessTimer.restart()
    }
    brightness = pct
    brightnessReady = true
  }

  Timer {
    id: brightnessTimer
    interval: 1500
    onTriggered: root.showBrightness = false
  }

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
      return isHovered ? root.pillHeight * 4 : root.pillHeight
    }
    implicitWidth: root.launcherActive ? root.pillHeight * 16
                : isHovered           ? root.pillHeight * 18
                : (root.showVolume || root.showBrightness) ? root.pillHeight * 12
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

    VolumeOSD {
      anchors.centerIn: parent
      vol: root.vol
      muted: root.muted
      opacity: visible ? 1 : 0
      visible: root.showVolume && !root.launcherActive && !root.showWorkspaces
      Behavior on opacity {
        NumberAnimation { duration: 2000; easing.type: Easing.OutCubic }
      }
    }

    BrightnessOSD {
      anchors.centerIn: parent
      level: root.brightness
      opacity: visible ? 1 : 0
      visible: root.showBrightness && !root.launcherActive && !root.showWorkspaces
      Behavior on opacity {
        NumberAnimation { duration: 2000; easing.type: Easing.OutCubic }
      }
    }

    Clock { visible: !root.launcherActive && !root.showWorkspaces && !root.showVolume && !root.showBrightness }
    Date { hovered: pill.isHovered; visible: !root.launcherActive && !root.showWorkspaces && !root.showVolume && !root.showBrightness }
    Battery { visible: !root.launcherActive && !root.showWorkspaces && !root.showVolume && !root.showBrightness }
  }
}
