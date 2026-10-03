import QtQuick
import QtQuick.Effects
import Quickshell

// Theme filmstrip that lives INSIDE the pill (same layout as WallpaperPicker).
// Focused card is big and bright, neighbours shrink/dim/desaturate as they slide away.
// Left/Right (or h/l) or the scroll wheel move, Enter or click on the focused card applies,
// click a neighbour to glide to it, type to search, Escape closes.
// Opened with `qs ipc call theme toggle`.
Item {
  id: root

  // ───── EDIT THESE ─────
  // Folder that holds your theme scripts.
  readonly property string scriptDir: Quickshell.env("HOME") + "/.config/rofi/themes/scripts/"

  // Wallpaper folders live in wallBase/<walls>. Picking a theme saves that folder
  // path into stateFile, and WallpaperPicker reads it when it opens.
  readonly property string wallBase: Quickshell.env("HOME") + "/.config/backgrounds/"
  readonly property string stateFile: Quickshell.env("HOME") + "/.cache/quickshell-wallpaper-dir"

  // To add a theme: add ONE entry.
  //   name   = shown on the card
  //   script = file in scriptDir (or a full path)
  //   walls  = folder name inside wallBase (case-sensitive!)
  //   bg / surface / accent / fg = the card colours + the 4 dots for that theme
  readonly property var themes: [
    { name: "One Dark",    script: "onedark.sh",     walls: "OneDark",
      bg: "#282c34", surface: "#3e4451", accent: "#61afef", fg: "#abb2bf" },
    { name: "Catppuccin",  script: "catppuccin.sh",  walls: "Catppuccin",
      bg: "#1e1e2e", surface: "#313244", accent: "#cba6f7", fg: "#cdd6f4" },
    { name: "Tokyo Night", script: "TokyoNight.sh",  walls: "TokyoNight",
      bg: "#1a1b26", surface: "#24283b", accent: "#7aa2f7", fg: "#c0caf5" },
    { name: "Gruvbox",     script: "Gruvbox.sh",     walls: "Gruvbox",
      bg: "#282828", surface: "#3c3836", accent: "#fabd2f", fg: "#ebdbb2" },
    { name: "Nord",        script: "nord.sh",        walls: "Nord",
      bg: "#2e3440", surface: "#3b4252", accent: "#88c0d0", fg: "#d8dee9" },
    { name: "Rosé Pine",   script: "RosePine.sh",    walls: "RosePine",
      bg: "#191724", surface: "#1f1d2e", accent: "#ebbcba", fg: "#e0def4" }
  ]
  // ──────────────────────

  signal closeRequested()   // Pill.qml listens to this and closes the strip

  implicitWidth: 480
  implicitHeight: 100       // Pill adds its own padding on top of this

  // ───── state ─────
  property string searchQuery: ""
  property var displayThemes: themes.filter(t =>
    t.name.toLowerCase().includes(root.searchQuery.trim().toLowerCase()))
  readonly property int count: displayThemes.length
  property int focusIndex: 0
  property real pos: 0

  function updateSearch() {
    root.focusIndex = 0
    root.pos = 0
  }

  function searchKey(event) {
    if (event.key === Qt.Key_Backspace) { root.searchQuery = root.searchQuery.slice(0, -1); root.updateSearch(); return true }
    if (event.key === Qt.Key_Space) { root.searchQuery += " "; root.updateSearch(); return true }
    if (event.text && event.text.length > 0 && !event.modifiers && /^[A-Za-z0-9._-]$/.test(event.text)) {
      root.searchQuery += event.text
      root.updateSearch()
      return true
    }
    return false
  }

  function move(delta) {
    if (count === 0) return
    focusIndex = Math.max(0, Math.min(count - 1, focusIndex + delta))
  }

  // ───── applying ─────
  function apply(theme) {
    if (!theme) return
    // absolute path stays as-is, otherwise it's looked up in scriptDir
    var path = theme.script.startsWith("/") ? theme.script : root.scriptDir + theme.script
    console.log("[theme] running:", path)

    // point the wallpaper picker at this theme's folder
    if (theme.walls) {
      var dir = root.wallBase + theme.walls
      console.log("[theme] wallpaper dir:", dir)
      Quickshell.execDetached(["sh", "-c",
        'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1"',
        "sh", root.stateFile, dir])
    }
    // run through bash; stdout+stderr go to /tmp/theme-menu.log so failures aren't silent
    Quickshell.execDetached(["bash", "-c",
      'echo "--- $(date) $1" >> /tmp/theme-menu.log; bash "$1" >> /tmp/theme-menu.log 2>&1; echo "exit: $?" >> /tmp/theme-menu.log',
      "theme-menu", path])
    root.closeRequested()
  }

  // fade in after the pill has finished resizing
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

  // ───── smooth scrolling ─────
  // Cards are drawn from this single `pos` value, which exponentially chases focusIndex.
  FrameAnimation {
    running: root.pos !== root.focusIndex
    onTriggered: {
      const k = 1 - Math.exp(-frameTime / 0.14)
      const next = root.pos + (root.focusIndex - root.pos) * k
      root.pos = Math.abs(next - root.focusIndex) < 0.005 ? root.focusIndex : next
    }
  }

  // ───── the "depth" look (same numbers as the wallpaper strip) ─────
  readonly property var slotW:      [160, 104, 84, 68, 56]    // card width
  readonly property var slotH:      [90, 58, 47, 38, 31]      // card height
  readonly property var slotCX:     [0, 118, 200, 262, 308]   // distance from center
  readonly property var slotBright: [1, 0.56, 0.42, 0.30, 0.22]
  readonly property var slotSat:    [1, 0.65, 0.55, 0.45, 0.40]

  function slotLerp(arr, ao) {
    if (ao >= 4) return arr[4]
    const i = Math.floor(ao)
    return arr[i] + (arr[i + 1] - arr[i]) * (ao - i)
  }

  function offsetX(off) {
    const ao = Math.abs(off)
    const cx = ao <= 4 ? slotLerp(slotCX, ao) : slotCX[4] + (ao - 4) * 60
    return off < 0 ? -cx : cx
  }

  // ───── HUD ─────
  Text {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 16
    anchors.topMargin: 4
    text: "Theme"
    color: "#eeffffff"
    font.pixelSize: 13
    font.weight: Font.Medium
    z: 100
  }

  Text {
    id: countText
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.rightMargin: 16
    anchors.topMargin: 8
    text: root.searchQuery.length > 0
        ? root.searchQuery + "  •  " + (root.count > 0 ? root.focusIndex + 1 : 0) + "/" + root.count
        : (root.count > 0 ? root.focusIndex + 1 : 0) + "/" + root.count
    color: "#bbffffff"
    font.pixelSize: 11
    horizontalAlignment: Text.AlignRight
    z: 100
  }

  Text {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: 16
    anchors.bottomMargin: 7
    text: "← / →   •   Return ↵"
    color: "#88ffffff"
    font.pixelSize: 10
    z: 100
  }

  Rectangle {
    visible: root.searchQuery.length > 0
    anchors.right: countText.left
    anchors.top: parent.top
    anchors.topMargin: 5
    anchors.rightMargin: 10
    width: Math.min(150, root.width * 0.25)
    height: 24
    radius: 7
    color: "#18ffffff"
    border.width: 1
    border.color: "#30ffffff"
    z: 101
    Text {
      anchors.fill: parent
      anchors.leftMargin: 9
      anchors.rightMargin: 9
      verticalAlignment: Text.AlignVCenter
      text: root.searchQuery
      color: "#eeffffff"
      font.pixelSize: 11
      elide: Text.ElideLeft
    }
  }

  // ───── cards ─────
  Repeater {
    model: root.displayThemes

    delegate: Item {
      id: tile
      required property var modelData
      required property int index

      readonly property real off: index - root.pos
      readonly property real ao: Math.abs(off)
      readonly property bool focused: index === root.focusIndex
      readonly property real bright: root.slotLerp(root.slotBright, ao)
      readonly property real sat: root.slotLerp(root.slotSat, ao)

      // fade out near the left/right edge so the strip ends soften instead of hard-cutting
      readonly property real edgeFade: Math.max(0, Math.min(1, Math.min(x, root.width - (x + width)) / 50))

      width: root.slotLerp(root.slotW, ao)
      height: root.slotLerp(root.slotH, ao)
      x: root.width / 2 + root.offsetX(off) - width / 2
      y: (root.height - height) / 2
      z: 10 - ao
      visible: ao <= 5
      opacity: edgeFade * (ao <= 4 ? 1 : Math.max(0, 5 - ao))

      // the card, painted in the theme's own background
      Rectangle {
        anchors.fill: parent
        radius: 8 + 2 * Math.max(0, 1 - tile.ao)
        color: tile.modelData.bg

        // desaturate cards the further they are from the center
        layer.enabled: tile.visible
        layer.effect: MultiEffect { saturation: tile.sat - 1 }

        // theme name (too small to read past ~2 steps away, so it fades out)
        Text {
          x: parent.width * 0.09
          y: parent.height * 0.12
          width: parent.width * 0.82
          text: tile.modelData.name
          color: tile.modelData.fg
          elide: Text.ElideRight
          opacity: tile.ao < 2.5 ? 1 : 0
          font {
            family: "SF Pro Display"
            pixelSize: Math.max(8, Math.round(13 * tile.width / 160))
            weight: Font.Medium
          }
        }

        // 4 dots: surface, accent, bg, fg
        Row {
          anchors.left: parent.left
          anchors.leftMargin: parent.width * 0.09
          anchors.bottom: parent.bottom
          anchors.bottomMargin: parent.height * 0.14
          spacing: dotSize * 0.45
          readonly property real dotSize: Math.max(6, tile.height * 0.17)

          Repeater {
            model: [tile.modelData.surface, tile.modelData.accent,
                    tile.modelData.bg, tile.modelData.fg]

            delegate: Rectangle {
              required property string modelData
              width: parent.dotSize
              height: parent.dotSize
              radius: width / 2
              color: modelData
              // thin outline so the bg dot is still visible on the bg-coloured card
              border.width: 1
              border.color: "#40ffffff"
            }
          }
        }

        // darken cards the further they are from the center
        Rectangle {
          anchors.fill: parent
          color: "black"
          opacity: 1 - tile.bright
        }
      }

      // thin outline, accent-coloured on the focused card
      Rectangle {
        anchors.fill: parent
        radius: 8 + 2 * Math.max(0, 1 - tile.ao)
        color: "transparent"
        border.width: tile.focused ? 2 : 1
        border.color: tile.focused ? tile.modelData.accent : "#22ffffff"
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // click the focused one = apply, click a neighbour = glide to it
        onClicked: tile.focused ? root.apply(tile.modelData) : root.focusIndex = tile.index
      }
    }
  }

  // shown when the search matches nothing
  Text {
    anchors.centerIn: parent
    visible: root.count === 0
    text: "No themes match"
    color: "#88ffffff"
    font.pixelSize: 12
  }

  // scroll wheel moves the strip (doesn't block clicks)
  MouseArea {
    anchors.fill: parent
    z: 20
    acceptedButtons: Qt.NoButton
    property real acc: 0
    onWheel: event => {
      acc += event.angleDelta.y / 120
      const notches = Math.trunc(acc)
      if (notches !== 0) {
        root.move(-notches)
        acc -= notches
      }
      event.accepted = true
    }
  }

  // keyboard
  focus: true
  Component.onCompleted: forceActiveFocus()
  Keys.onPressed: event => {
    let handled = true
    if (event.key === Qt.Key_Escape) {
      if (root.searchQuery.length > 0) { root.searchQuery = ""; root.updateSearch() }
      else closeRequested()
    }
    else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) move(-1)
    else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) move(1)
    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) apply(root.displayThemes[root.focusIndex])
    else handled = root.searchKey(event)
    event.accepted = handled
  }
}
