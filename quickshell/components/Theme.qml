import QtQuick
import QtQuick.Layouts
import Quickshell

// Second-level menu: pick a theme. Opened with `qs ipc call theme toggle`.
// Picking one runs your existing theme script with the theme id as its argument.
Item {
  id: root

  // ───── EDIT THESE ─────
  // Folder that holds your theme scripts.
  readonly property string scriptDir: Quickshell.env("HOME") + "/.config/rofi/themes/scripts/"

  // Wallpaper folders live in wallBase/<walls>. Picking a theme saves that folder
  // path into stateFile, and WallpaperPicker reads it when it opens.
  readonly property string wallBase: Quickshell.env("HOME") + "/.config/backgrounds/"
  readonly property string stateFile: Quickshell.env("HOME") + "/.cache/quickshell-wallpaper-dir"

  // To add a theme: add ONE line.
  //   name   = shown in menu
  //   script = file in scriptDir (or a full path)
  //   walls  = folder name inside wallBase (case-sensitive!)
  readonly property var themes: [
    { name: "One Dark",    script: "onedark.sh",     walls: "OneDark" },
    { name: "Catppuccin",  script: "catppuccin.sh",  walls: "Catppuccin" },
    { name: "Tokyo Night", script: "TokyoNight.sh",  walls: "TokyoNight" },
    { name: "Gruvbox",     script: "Gruvbox.sh",     walls: "Gruvbox" },
    { name: "Nord",        script: "nord.sh",        walls: "Nord" },
    { name: "Rosé Pine",   script: "RosePine.sh",    walls: "RosePine" }
  ]
  // ──────────────────────

  readonly property int rowHeight: 46
  readonly property int rowSpacing: 4
  readonly property int maxVisibleRows: 6
  readonly property int searchBarHeight: 60
  readonly property int sectionSpacing: 10

  property string query: ""
  property var displayThemes: themes.filter(t =>
    t.name.toLowerCase().includes(query.toLowerCase()))

  readonly property int visibleRows: Math.max(1, Math.min(displayThemes.length, maxVisibleRows))
  readonly property real listHeight: displayThemes.length === 0
      ? rowHeight
      : visibleRows * rowHeight + (visibleRows - 1) * rowSpacing

  implicitWidth: 480
  implicitHeight: searchBarHeight + sectionSpacing + listHeight

  signal closeRequested()

  function apply(theme) {
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

  clip: true

  ColumnLayout {
    anchors.fill: parent
    spacing: root.sectionSpacing

    // search bar
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.searchBarHeight
      radius: 99
      color: "#000000"

      TextInput {
        id: searchInput
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        verticalAlignment: TextInput.AlignVCenter
        focus: true
        color: "#e8eaed"
        font {
          family: "SF Pro Display"
          pixelSize: 15
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: searchInput.text.length === 0
          text: "Search themes"
          color: "#666666"
          font: searchInput.font
        }

        onTextChanged: {
          root.query = text
          list.currentIndex = 0
        }

        Keys.onEscapePressed: root.closeRequested()
        Keys.onReturnPressed: {
          var i = list.currentIndex
          if (i >= 0 && i < root.displayThemes.length)
            root.apply(root.displayThemes[i])
        }
        Keys.onDownPressed: {
          list.incrementCurrentIndex()
          list.positionViewAtIndex(list.currentIndex, ListView.Contain)
        }
        Keys.onUpPressed: {
          list.decrementCurrentIndex()
          list.positionViewAtIndex(list.currentIndex, ListView.Contain)
        }
      }
    }

    ListView {
      id: list
      Layout.fillWidth: true
      Layout.preferredHeight: root.listHeight
      clip: true
      spacing: root.rowSpacing
      model: root.displayThemes
      currentIndex: 0
      highlightMoveDuration: 100

      Text {
        anchors.centerIn: parent
        visible: list.count === 0
        text: "Nothing Found"
        color: "#666666"
        font.pixelSize: 14
      }

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

        Rectangle {
          implicitWidth: list.currentIndex === entry.index ? 4 : 0
          implicitHeight: list.currentIndex === entry.index ? 20 : 0
          anchors.verticalCenter: parent.verticalCenter
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
          onClicked: root.apply(entry.modelData)
        }
      }
    }
  }

  Component.onCompleted: searchInput.forceActiveFocus()
}
