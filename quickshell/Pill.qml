import Quickshell
import QtQuick
import Quickshell.Wayland          // layer-shell (WlrLayershell) + keyboard focus
import QtQuick.Layouts
import Quickshell.Io               // Process, IpcHandler, SplitParser
import Quickshell.Hyprland         // workspace events + HyprlandFocusGrab
import Quickshell.Services.Pipewire        // volume
import Quickshell.Services.Notifications   // notification daemon
import "./components"              // Launcher, Menu, Workspaces, WallpaperPicker, Clock, ...

PanelWindow {
  id: root

  // ───── sizing / colors ─────
  property int pillHeight: 30      // height of the idle pill; most sizes below are multiples of this
  property int radius: 16          // base corner radius
  property color bg1: Colors.scrim    // pill background

  // ───── MODES: each is a simple on/off switch ─────
  property bool launcherActive: false
  property bool menuActive: false
  property bool wallpaperActive: false
  property bool themeActive: false
  property bool calendarActive: false
  property bool notifActive: false

  property var toastNotif: null
  property bool showToast: false
  property int toastDuration: 3000   // ms the toast stays before the pill goes back to normal

  readonly property bool panelWanted: ShellState.panel !== ""
  property string shownPanel: ""
  property bool panelFadeIn: false      // target for the panel's fade (true = visible)
  readonly property bool panelActive: shownPanel !== ""

  readonly property bool anyModeOpen: launcherActive || menuActive || wallpaperActive || themeActive || calendarActive || notifActive || panelActive

  function closeBigModes() {
    launcherActive = false
    menuActive = false
    wallpaperActive = false
    themeActive = false
    calendarActive = false
    notifActive = false
  }

  function openCalendar() {
    ShellState.close()
    closeBigModes()
    calendarActive = true
  }

  property bool showWorkspaces: pill.rootTimer.running

  // Open / close / swap a panel with a fade. Runs whenever ShellState.panel changes.
  function syncPanel() {
    const want = ShellState.panel
    panelHideTimer.stop()
    panelSwapTimer.stop()
    if (want === "") {                      // closing: fade out, then unload
      panelFadeIn = false
      panelHideTimer.restart()
    } else if (shownPanel === "" || shownPanel === want) {   // opening (or re-opening mid-fade)
      shownPanel = want
      panelFadeIn = true
    } else {                                // switching panel: fade old out, swap, fade new in
      panelFadeIn = false
      panelSwapTimer.restart()
    }
  }
  Connections {
    target: ShellState
    function onPanelChanged() { root.syncPanel() }
  }
  Timer { id: panelHideTimer; interval: 180; onTriggered: root.shownPanel = "" }
  Timer {
    id: panelSwapTimer
    interval: 180
    onTriggered: { root.shownPanel = ShellState.panel; root.panelFadeIn = true }
  }

  NotificationServer {
    id: notifServer
    bodySupported: true
    actionsSupported: true
    imageSupported: true
    keepOnReload: true
    onNotification: n => {
      n.tracked = true
      root.pokeToast(n)
    }
  }

  function pokeToast(n) {
    if (anyModeOpen) return            // panel/launcher/etc. already own the pill
    toastNotif = n
    showVolume = false                 // the toast wins over the OSDs
    showBrightness = false
    showToast = true
    toastTimer.interval = toastDuration
    toastTimer.restart()
  }

  // Click on the toast -> open the full panel.
  function openNotifs() {
    showToast = false
    ShellState.close()
    closeBigModes()
    notifActive = true
  }

  Timer {
    id: toastTimer
    onTriggered: root.showToast = false
  }

  Connections {
    target: pill
    function onIsHoveredChanged() {
      if (!root.showToast) return
      if (pill.isHovered) toastTimer.stop()
      else toastTimer.restart()
    }
  }

  Connections {
    target: root.toastNotif
    function onClosed() { root.showToast = false }
  }

  readonly property var sink: Pipewire.defaultAudioSink          // current default output device
  readonly property real vol: sink?.audio?.volume ?? 0           // 0..1 (can go above 1)
  readonly property bool muted: sink?.audio?.muted ?? false
  property bool showVolume: false

  PwObjectTracker { objects: [root.sink] }

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

  Timer {
    interval: 250
    running: true
    repeat: true
    onTriggered: if (!brightnessProc.running) brightnessProc.running = true
  }

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
    Backend.brightness = pct * 100   // the control panel's brightness slider reads this
    brightnessReady = true
  }

  Timer {
    id: brightnessTimer
    interval: 1500
    onTriggered: root.showBrightness = false
  }

  color: "transparent"
  anchors { top: true; left: true; right: true }

  implicitHeight: pillHeight * 20

  WlrLayershell.layer: WlrLayer.Top

  WlrLayershell.keyboardFocus: root.anyModeOpen
      ? WlrKeyboardFocus.OnDemand
      : WlrKeyboardFocus.None

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
  HyprlandFocusGrab {
    windows: [ root ]
    active: root.calendarActive
    onCleared: root.calendarActive = false
  }

  HyprlandFocusGrab {
    windows: [ root ]
    active: root.notifActive
    onCleared: root.notifActive = false
  }

  HyprlandFocusGrab {
    windows: [ root ]
    active: root.panelActive
    onCleared: ShellState.close()
  }

  exclusiveZone: pillHeight

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      ShellState.close()
      root.wallpaperActive = false
      root.menuActive = false
      root.themeActive = false
      root.calendarActive = false
      root.notifActive = false
      root.launcherActive = !root.launcherActive
    }
  }
  IpcHandler {
    target: "menu"

    function toggle(): void {
      ShellState.close()
      root.launcherActive = false
      root.wallpaperActive = false
      root.themeActive = false
      root.calendarActive = false
      root.notifActive = false
      root.menuActive = !root.menuActive
    }
  }
  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      ShellState.close()
      root.launcherActive = false
      root.menuActive = false
      root.themeActive = false
      root.calendarActive = false
      root.notifActive = false
      root.wallpaperActive = !root.wallpaperActive
    }
  }
  IpcHandler {
    target: "theme"

    function toggle(): void {
      ShellState.close()
      root.launcherActive = false
      root.menuActive = false
      root.wallpaperActive = false
      root.calendarActive = false
      root.notifActive = false
      root.themeActive = !root.themeActive
    }
  }
  IpcHandler {
    target: "calendar"

    function toggle(): void {
      const wasOpen = root.calendarActive
      ShellState.close()
      root.closeBigModes()
      root.calendarActive = !wasOpen
    }
  }
  IpcHandler {
    target: "notifications"

    function toggle(): void {
      const wasOpen = root.notifActive
      ShellState.close()
      root.closeBigModes()
      root.notifActive = !wasOpen
    }
  }

  // The four panels. Opening one closes the others; calling it again closes it.
  IpcHandler {
    target: "control"

    function toggle(): void {
      root.closeBigModes()
      ShellState.toggle("control")
    }
  }
  IpcHandler {
    target: "capture"

    function toggle(): void {
      root.closeBigModes()
      ShellState.toggle("capture")
    }
  }
  IpcHandler {
    target: "clipboard"

    function toggle(): void {
      root.closeBigModes()
      ShellState.toggle("clipboard")
    }
  }
  IpcHandler {
    target: "power"

    function toggle(): void {
      root.closeBigModes()
      ShellState.toggle("power")
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

    property alias rootTimer: rootTimer

    HoverHandler { id: hover }
    property bool isHovered: hover.hovered

    property bool isOpen: isHovered || root.anyModeOpen || root.showToast

    property bool isShowing: isHovered || root.showWorkspaces

    implicitHeight: {
      if (root.wallpaperActive && wallLoader.item)       // wallpaper strip: its own height + padding
        return wallLoader.item.implicitHeight + 20
      if (root.themeActive && themeLoader.item)          // theme list
        return themeLoader.item.implicitHeight + 20
      if (root.panelWanted && panelLoader.item)          // control / capture / clipboard / power
        return panelLoader.item.implicitHeight + 20
      if (root.notifActive && notifLoader.item)          // notifications
        return notifLoader.item.implicitHeight + 20
      if (root.calendarActive && calendarLoader.item)    // calendar
        return calendarLoader.item.implicitHeight + 20
      if (root.launcherActive && launcherLoader.item)    // launcher: as tall as its content + padding
        return launcherLoader.item.implicitHeight + 20
      if (root.menuActive && menuLoader.item)            // layout menu
        return menuLoader.item.implicitHeight + 20
      if (root.showToast)                                // notification toast
        return toast.implicitHeight + 20
      if (root.showVolume)                               // OSDs: just slightly taller than idle
        return root.pillHeight + 5
      if (root.showBrightness)
        return root.pillHeight + 5
      return isHovered ? root.pillHeight * 5 : root.pillHeight   // hover expands, else idle
    }

    implicitWidth: root.wallpaperActive ? root.pillHeight * 24     // wide: the strip needs room for 9 thumbs
                : root.themeActive ? root.pillHeight * 24
                : (root.panelWanted && panelLoader.item) ? panelLoader.item.implicitWidth + 20   // panels size themselves
                : root.notifActive ? (notifLoader.item ? notifLoader.item.implicitWidth + 20 : root.pillHeight * 14)
                : root.calendarActive ? (calendarLoader.item ? calendarLoader.item.implicitWidth + 20 : root.pillHeight * 12)
                : root.launcherActive ? root.pillHeight * 16
                : root.menuActive ? root.pillHeight * 16
                : root.showToast      ? root.pillHeight * 14
                : isHovered           ? root.pillHeight * 12
                : (root.showVolume || root.showBrightness) ? root.pillHeight * 12
                : root.showWorkspaces           ? root.pillHeight * 4
                :                       root.pillHeight * 3        // idle

    topLeftRadius: isOpen ? root.radius * 0 : root.radius * 0
    topRightRadius: isOpen ? root.radius * 0 : root.radius * 0
    bottomRightRadius: isOpen ? root.radius * 2 : root.radius
    bottomLeftRadius: isOpen ? root.radius * 2 : root.radius

    Behavior on bottomLeftRadius {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    Behavior on bottomRightRadius {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    // (animates the old single `radius`, the per-corner radii above don't use it)
    Behavior on radius {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }

    ConcaveCurves {
      anchors.top: parent.top
      anchors.right: parent.left    // left of the pill
      mirrored: true
      radius: pill.isHovered ? 32 : (pill.isOpen ? 32 : root.radius)
      color: root.bg1

      Behavior on radius {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
      }
    }

    ConcaveCurves {
      anchors.top: parent.top
      anchors.left: parent.right    // right of the pill
      radius: pill.isHovered ? 32 : (pill.isOpen ? 32 : root.radius)
      color: root.bg1

      Behavior on radius {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
      }
    }

    color: root.bg1

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

    Item {
      anchors.fill: parent
      anchors.margins: 10
      clip: true

      Loader {
        id: calendarLoader
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width      // calendar stretches to the pill's width

        active: root.calendarActive || opacity > 0     // stay loaded until the fade-out ends
        sourceComponent: Calendar {}

        opacity: root.calendarActive ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: root.calendarActive ? 250 : 120; easing.type: Easing.OutCubic }
        }
      }
    }

    Item {
      anchors.fill: parent
      anchors.margins: 10
      clip: true

      Loader {
        id: notifLoader
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0

        active: root.notifActive || opacity > 0     // stay loaded until the fade-out ends
        sourceComponent: notifPanel
        onLoaded: item.takeInitialFocus()

        opacity: root.notifActive ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: root.notifActive ? 250 : 120; easing.type: Easing.OutCubic }
        }
      }
    }
    Component { id: notifPanel; NotificationPanel { notifications: notifServer.trackedNotifications } }

    Item {
      id: panelClip
      anchors.fill: parent
      anchors.margins: 10
      clip: true

      Loader {
        id: panelLoader
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: item ? item.implicitWidth : 0
        height: item ? item.implicitHeight : 0

        active: root.panelActive
        sourceComponent: root.shownPanel === "control" ? controlPanel
                       : root.shownPanel === "capture" ? capturePanel
                       : root.shownPanel === "clipboard" ? clipboardPanel
                       : root.shownPanel === "power" ? powerPanel
                       : null
        onLoaded: if (item.takeInitialFocus) item.takeInitialFocus()

        opacity: root.panelFadeIn ? 1 : 0
        Behavior on opacity {
          NumberAnimation { duration: root.panelFadeIn ? 280 : 150; easing.type: Easing.OutCubic }
        }

        transform: Translate {
          y: root.panelFadeIn ? 0 : -8
          Behavior on y {
            NumberAnimation { duration: root.panelFadeIn ? 280 : 150; easing.type: Easing.OutCubic }
          }
        }
      }
    }
    Component { id: controlPanel; ControlPanel {} }
    Component { id: capturePanel; CapturePanel {} }
    Component { id: clipboardPanel; ClipboardPanel {} }
    Component { id: powerPanel; PowerPanel {} }

    // Workspace dots, fades in/out
    Loader {
      id: wsLoader
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      active: root.showWorkspaces && !root.anyModeOpen && !root.showToast
      visible: root.showWorkspaces && !root.anyModeOpen && !root.showToast
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
    Connections {
      target: calendarLoader.item
      function onCloseRequested() { root.calendarActive = false }
    }
    Connections {
      target: notifLoader.item
      function onCloseRequested() { root.notifActive = false }
    }

    // ───── NOTIFICATION TOAST ─────
    NotifToast {
      id: toast
      anchors.fill: parent
      anchors.margins: 10
      notif: root.toastNotif
      opacity: (root.showToast && !root.anyModeOpen) ? 1 : 0
      visible: opacity > 0
      Behavior on opacity {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
      }
      onClicked: root.openNotifs()
      onDismissed: {
        root.showToast = false
        root.toastNotif?.dismiss()
      }
    }

    VolumeOSD {
      anchors.centerIn: parent
      vol: root.vol
      muted: root.muted
      opacity: visible ? 1 : 0
      visible: root.showVolume && !root.anyModeOpen && !root.showWorkspaces && !root.showToast
      Behavior on opacity {
        NumberAnimation { duration: 2000; easing.type: Easing.OutCubic }
      }
    }

    BrightnessOSD {
      anchors.centerIn: parent
      level: root.brightness
      opacity: visible ? 1 : 0
      visible: root.showBrightness && !root.anyModeOpen && !root.showWorkspaces && !root.showToast
      Behavior on opacity {
        NumberAnimation { duration: 2000; easing.type: Easing.OutCubic }
      }
    }

    DateWidget {
      hovered: pill.isHovered
      visible: !root.anyModeOpen && !root.showWorkspaces && !root.showVolume && !root.showBrightness && !root.showToast
      onClicked: root.openCalendar()
    }
  }
}
