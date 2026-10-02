// ─────────────────────────────────────────────────────────────────────────────
// Pill.qml: the whole shell is this one pill at the top of the screen.
//
// The pill is a black rounded rectangle that changes size depending on what it
// is showing. Layout of this file, top to bottom:
//   1. imports
//   2. state (which "mode" the pill is in) + volume / brightness logic
//   3. the window itself (a transparent layer-shell surface covering the top)
//   4. IPC handlers (keybinds talk to the shell through these)
//   5. the pill Rectangle: its size, shape, and everything drawn inside it
//
// Modes, in priority order for sizing:
//   wallpaper strip > theme > launcher > menu > volume/brightness popup > hover > idle
// ─────────────────────────────────────────────────────────────────────────────
import Quickshell
import QtQuick
import Quickshell.Wayland          // layer-shell (WlrLayershell) + keyboard focus
import QtQuick.Layouts
import Quickshell.Io               // Process, IpcHandler, SplitParser
import Quickshell.Hyprland         // workspace events + HyprlandFocusGrab
import Quickshell.Services.Pipewire        // volume
import Quickshell.Services.Notifications   // (imported, not used yet)
import "./components"              // Launcher, Menu, Workspaces, WallpaperPicker, Clock, ...

PanelWindow {
  id: root

  // ───── sizing / colors ─────
  property int pillHeight: 30      // height of the idle pill; most sizes below are multiples of this
  property int radius: 16          // base corner radius
  property color bg1: "#000000"    // pill background

  // ───── MODES: each is a simple on/off switch ─────
  // LAUNCHER: the keybind flips it, Escape/launching an app clears it.
  property bool launcherActive: false
  // MENU: LayoutMenu (Wallpaper / Theme). Flipped by `ipc call menu toggle`.
  property bool menuActive: false
  // WALLPAPER: the wallpaper strip. Flipped by `ipc call wallpaper toggle`.
  property bool wallpaperActive: false
  // THEME: the theme list. Flipped by `ipc call theme toggle`.
  property bool themeActive: false

  // true while any big mode owns the pill (used to hide OSDs / idle content)
  readonly property bool anyModeOpen: launcherActive || menuActive || wallpaperActive || themeActive

  // WORKSPACES: true for 1s after the focused workspace changes (see rootTimer below).
  property bool showWorkspaces: pill.rootTimer.running

  // ───── VOLUME ─────
  // The pill shows the volume bar for 1.5s after any volume/mute change.
  readonly property var sink: Pipewire.defaultAudioSink          // current default output device
  readonly property real vol: sink?.audio?.volume ?? 0           // 0..1 (can go above 1)
  readonly property bool muted: sink?.audio?.muted ?? false
  property bool showVolume: false

  // Without this tracker Pipewire doesn't keep the sink's volume up to date.
  PwObjectTracker { objects: [root.sink] }

  // Any volume or mute change pops the OSD.
  Connections {
    target: root.sink?.audio ?? null
    function onVolumeChanged() { root.pokeVolume() }
    function onMutedChanged()  { root.pokeVolume() }
  }

  // Show the volume popup and (re)start its hide timer.
  function pokeVolume() {
    if (anyModeOpen) return   // don't pop up over an open menu
    showBrightness = false                          // volume and brightness never show together
    showVolume = true
    volumeTimer.restart()
  }

  Timer {
    id: volumeTimer
    interval: 1500
    onTriggered: root.showVolume = false
  }

  // ───── BRIGHTNESS ─────
  // Same idea. Polls brightnessctl and pops the pill when the value changes.
  property real brightness: 0
  property bool brightnessReady: false   // false until the first read (so startup doesn't pop up)
  property bool showBrightness: false

  Process {
    id: brightnessProc
    command: ["brightnessctl", "-m"]     // machine-readable output, one line
    stdout: SplitParser {
      onRead: data => root.updateBrightness(data)
    }
  }

  // Re-run brightnessctl every 250ms (skipped if the previous run hasn't finished).
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
    if (brightnessReady && pct !== brightness && !anyModeOpen) {
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

  // ───── THE WINDOW ─────
  // A transparent strip across the top of the screen. The visible pill is drawn
  // inside it and the `mask` below makes everything else click-through.
  color: "transparent"
  anchors { top: true; left: true; right: true }

  // Window is tall enough for the biggest the pill can get; it is invisible anyway.
  implicitHeight: pillHeight * 14

  WlrLayershell.layer: WlrLayer.Top

  // The window only takes keyboard input while a keyboard-driven mode is open,
  // otherwise typing would go to the pill instead of your apps.
  WlrLayershell.keyboardFocus: root.anyModeOpen
      ? WlrKeyboardFocus.OnDemand
      : WlrKeyboardFocus.None

  // Click anywhere outside the pill while a mode is open -> close that mode.
  HyprlandFocusGrab {
    windows: [ root ]
    active: root.launcherActive
    onCleared: root.launcherActive = false
  }
  HyprlandFocusGrab {
    windows: [ root ]
    active: root.menuActive
    onCleared: root.menuActive = false
  }
  HyprlandFocusGrab {
    windows: [ root ]
    active: root.wallpaperActive
    onCleared: root.wallpaperActive = false
  }
  HyprlandFocusGrab {
    windows: [ root ]
    active: root.themeActive
    onCleared: root.themeActive = false
  }

  // Reserve this much space at the top so windows don't open underneath the pill.
  exclusiveZone: pillHeight

  // ───── IPC (keybinds) ─────
  // Hyprland binds call these, e.g.  bind = SUPER, W, exec, qs ipc call wallpaper toggle
  // Opening one mode closes the others so they never overlap.
  IpcHandler {
    target: "launcher"

    function toggle(): void {
      root.wallpaperActive = false
      root.menuActive = false
      root.themeActive = false
      root.launcherActive = !root.launcherActive
    }
  }
  IpcHandler {
    target: "menu"

    function toggle(): void {
      root.launcherActive = false
      root.wallpaperActive = false
      root.themeActive = false
      root.menuActive = !root.menuActive
    }
  }
  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      root.launcherActive = false
      root.menuActive = false
      root.themeActive = false
      root.wallpaperActive = !root.wallpaperActive
    }
  }
  IpcHandler {
    target: "theme"

    function toggle(): void {
      root.launcherActive = false
      root.menuActive = false
      root.wallpaperActive = false
      root.themeActive = !root.themeActive
    }
  }


  // Only the pill area receives mouse input. The rest of the window is click-through.
  mask: Region {
    item: pill
  }

  // Whenever you switch workspace, restart the 1s timer -> showWorkspaces turns on.
  Connections {
    target: Hyprland
    function onFocusedWorkspaceChanged() {
      pill.rootTimer.restart()
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // THE PILL
  // ───────────────────────────────────────────────────────────────────────────
  Rectangle {
    id: pill

    // Expose the Timer as a real property so `root` can reach it.
    // Without this alias, only code inside this Rectangle could see `rootTimer`.
    property alias rootTimer: rootTimer

    HoverHandler { id: hover }
    property bool isHovered: hover.hovered

    // "Open" pills get rounder bottom corners (see the radius lines below).
    property bool isOpen: isHovered || root.anyModeOpen
    // (unused right now, safe to delete or use later)
    property bool isShowing: isHovered || root.showWorkspaces

    // HEIGHT: first matching line wins, so order = priority.
    implicitHeight: {
      if (root.wallpaperActive && wallLoader.item)       // wallpaper strip: its own height + padding
        return wallLoader.item.implicitHeight + 20
      if (root.themeActive && themeLoader.item)          // theme list
        return themeLoader.item.implicitHeight + 20
      if (root.launcherActive && launcherLoader.item)    // launcher: as tall as its content + padding
        return launcherLoader.item.implicitHeight + 20
      if (root.menuActive && menuLoader.item)            // layout menu
        return menuLoader.item.implicitHeight + 20
      if (root.showVolume)                               // OSDs: just slightly taller than idle
        return root.pillHeight + 5
      if (root.showBrightness)
        return root.pillHeight + 5
      return isHovered ? root.pillHeight * 4 : root.pillHeight   // hover expands, else idle
    }

    // WIDTH: same idea, first match wins.
    implicitWidth: root.wallpaperActive ? root.pillHeight * 24     // wide: the strip needs room for 9 thumbs
                : root.themeActive ? root.pillHeight * 16
                : root.launcherActive ? root.pillHeight * 16
                : root.menuActive ? root.pillHeight * 16
                : isHovered           ? root.pillHeight * 18
                : (root.showVolume || root.showBrightness) ? root.pillHeight * 12
                : root.showWorkspaces           ? root.pillHeight * 4
                :                       root.pillHeight * 3        // idle

    // The pill hangs from the top edge, so the top corners stay square (0) and
    // only the bottom corners are rounded. Open = twice as round.
    topLeftRadius: isOpen ? root.radius * 0 : root.radius * 0
    topRightRadius: isOpen ? root.radius * 0 : root.radius * 0
    bottomRightRadius: isOpen ? root.radius * 2 : root.radius
    bottomLeftRadius: isOpen ? root.radius * 2 : root.radius

    // (animates the old single `radius`, the per-corner radii above don't use it)
    Behavior on radius {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // The two little concave "ears" on each side of the pill's top, so the pill
    // looks like it flows out of the screen edge.
    ConcaveCurves {
      anchors.top: parent.top
      anchors.right: parent.left    // left of the pill
      mirrored: true
      radius: root.radius
      color: root.bg1
    }

    ConcaveCurves {
      anchors.top: parent.top
      anchors.left: parent.right    // right of the pill
      radius: root.radius
      color: root.bg1
    }

    color: root.bg1

    // Aligns to the top center so expansion happens downward and outwards
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    // Smoothly animate every size change (this is what makes it "expand").
    Behavior on implicitHeight {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    Behavior on implicitWidth {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // How long the workspace switcher stays visible after a workspace change.
    Timer {
      id: rootTimer
      interval: 1000
      running: false
      repeat: false
    }

    // ───── CONTENT: Loaders only create their content while the mode is on ─────

    // App launcher
    Loader {
      id: launcherLoader
      anchors.fill: parent
      anchors.margins: 10

      active: root.launcherActive
      sourceComponent: Launcher {}
    }
    // Layout menu (components/LayoutMenu.qml)
    Loader {
      id: menuLoader
      anchors.fill: parent
      anchors.margins: 10

      active: root.menuActive
      sourceComponent: LayoutMenu {}
    }
    // Theme list (components/Theme.qml)
    Loader {
      id: themeLoader
      anchors.fill: parent
      anchors.margins: 10

      active: root.themeActive
      sourceComponent: Theme {}
    }
    // Wallpaper strip (components/WallpaperPicker.qml)
    Loader {
      id: wallLoader
      anchors.fill: parent
      anchors.margins: 10

      active: root.wallpaperActive
      sourceComponent: WallpaperPicker {}
    }

    // Workspace dots, fades in/out
    Loader {
      id: wsLoader
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      active: root.showWorkspaces && !root.anyModeOpen
      visible: root.showWorkspaces && !root.anyModeOpen
      sourceComponent: Workspaces {}
      opacity: root.showWorkspaces ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
      }
    }

    // Each of these components emits `closeRequested()` (Escape, app launched, ...).
    // These hooks turn that signal into "switch my mode off".
    Connections {
      target: launcherLoader.item
      function onCloseRequested() { root.launcherActive = false }
    }
    Connections {
      target: menuLoader.item
      function onCloseRequested() { root.menuActive = false }
    }
    Connections {
      target: wallLoader.item
      function onCloseRequested() { root.wallpaperActive = false }
    }
    Connections {
      target: themeLoader.item
      function onCloseRequested() { root.themeActive = false }
    }

    // ───── OSDs ─────
    // Hidden while any bigger mode is showing.
    VolumeOSD {
      anchors.centerIn: parent
      vol: root.vol
      muted: root.muted
      opacity: visible ? 1 : 0
      visible: root.showVolume && !root.anyModeOpen && !root.showWorkspaces
      Behavior on opacity {
        NumberAnimation { duration: 2000; easing.type: Easing.OutCubic }
      }
    }

    BrightnessOSD {
      anchors.centerIn: parent
      level: root.brightness
      opacity: visible ? 1 : 0
      visible: root.showBrightness && !root.anyModeOpen && !root.showWorkspaces
      Behavior on opacity {
        NumberAnimation { duration: 2000; easing.type: Easing.OutCubic }
      }
    }

    // ───── IDLE CONTENT ─────
    // The normal clock / date / battery, hidden whenever anything else is using the pill.
    Clock { visible: !root.anyModeOpen && !root.showWorkspaces && !root.showVolume && !root.showBrightness }
    Date { hovered: pill.isHovered; visible: !root.anyModeOpen && !root.showWorkspaces && !root.showVolume && !root.showBrightness }
    Battery { visible: !root.anyModeOpen && !root.showWorkspaces && !root.showVolume && !root.showBrightness }
  }
}
