import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
  id: root

  // Main visual controls
  property int imageRadius: 12
  property real selectedScale: 1.10
  property int selectedLift: 4

  readonly property int cardWidth: 160
  readonly property int cardHeight: 100
  readonly property int cardSpacing: 10
  readonly property int sidePadding: 20
  readonly property int maxVisible: 4
  readonly property int viewportWidth: (maxVisible * cardWidth) + ((maxVisible - 1) * cardSpacing) + (sidePadding * 2)

  property var wallpapers: []
  property int currentIndex: 0
  property string savedWallpaperPath: ""

  // Stores the exact wallpaper path that was last applied.
  // This survives Quickshell restarts.
  readonly property string wallpaperStateFile: "$HOME/.config/quickshell/current-wallpaper"

  signal closeRequested()

  implicitWidth: root.viewportWidth + 50
  implicitHeight: 180

  opacity: 0
  Behavior on opacity {
    NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
  }

  Timer {
    interval: 120
    running: true
    repeat: false
    onTriggered: root.opacity = 1
  }

  function loadWallpapers() {
    savedWallpaperReader.running = true
    wallpaperReader.running = true
  }

  function restoreSavedWallpaper() {
    if (root.savedWallpaperPath.length === 0 || root.wallpapers.length === 0)
      return

    var savedIndex = root.wallpapers.indexOf(root.savedWallpaperPath)
    if (savedIndex >= 0) {
      root.currentIndex = savedIndex
      wallpapersList.positionViewAtIndex(savedIndex, ListView.Center)
    }
  }

  function applyCurrent() {
    if (root.wallpapers.length === 0 || root.currentIndex < 0)
      return

    // Do not modify Process.command from JavaScript. Keep the selected path
    // as a normal Process argument so paths containing spaces work correctly.
    awwwProcess.wallpaperPath = root.wallpapers[root.currentIndex]
    awwwProcess.running = true
  }

  function next() {
    if (root.wallpapers.length === 0)
      return

    root.currentIndex = (root.currentIndex + 1) % root.wallpapers.length
    wallpapersList.positionViewAtIndex(root.currentIndex, ListView.Center)
  }

  function previous() {
    if (root.wallpapers.length === 0)
      return

    root.currentIndex = (root.currentIndex - 1 + root.wallpapers.length) % root.wallpapers.length
    wallpapersList.positionViewAtIndex(root.currentIndex, ListView.Center)
  }

  Process {
    id: savedWallpaperReader

    command: [
      "bash", "-lc",
      "if [ -f \"$HOME/.config/quickshell/current-wallpaper\" ]; then " +
      "cat \"$HOME/.config/quickshell/current-wallpaper\"; " +
      "fi"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        root.savedWallpaperPath = text.trim()
        root.restoreSavedWallpaper()
      }
    }
  }

  Process {
    id: wallpaperReader

    command: [
      "bash", "-lc",
      "find \"$HOME/Pictures/Wallpaper\" -maxdepth 1 -type f \\\n" +
      "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o " +
      "-iname '*.webp' -o -iname '*.gif' \\) -print | sort"
    ]

    stdout: StdioCollector {
      onStreamFinished: {
        var output = text.trim()
        root.wallpapers = output.length > 0
          ? output.split("\n").filter(function(path) { return path.length > 0 })
          : []

        if (root.currentIndex >= root.wallpapers.length)
          root.currentIndex = Math.max(0, root.wallpapers.length - 1)

        root.restoreSavedWallpaper()

        if (root.wallpapers.length > 0)
          wallpapersList.positionViewAtIndex(root.currentIndex, ListView.Center)
      }
    }
  }

  Process {
    id: awwwProcess

    property string wallpaperPath: ""

    // Quickshell inherits the compositor's environment, which may not contain
    // the same PATH as an interactive terminal. Add the usual user binary
    // locations explicitly, then let bash locate awww/awww-daemon.
    command: [
      "bash", "-lc",
      "export PATH=\"$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:/usr/bin:/bin:$PATH\"; " +
      "STATE_FILE=\"$HOME/.config/quickshell/current-wallpaper\"; " +
      "AWWW=\"$(command -v awww)\"; " +
      "DAEMON=\"$(command -v awww-daemon)\"; " +
      "if [ -z \"$AWWW\" ]; then echo 'wallpaper_switcher: awww not found in PATH' >&2; exit 127; fi; " +
      "if ! \"$AWWW\" query >/dev/null 2>&1; then " +
      "  if [ -z \"$DAEMON\" ]; then echo 'wallpaper_switcher: awww-daemon not found' >&2; exit 127; fi; " +
      "  \"$DAEMON\" >/dev/null 2>&1 & " +
      "  for i in 1 2 3 4 5 6 7 8 9 10; do " +
      "    sleep 0.1; \"$AWWW\" query >/dev/null 2>&1 && break; " +
      "  done; " +
      "fi; " +
      "\"$AWWW\" img \"$1\" --transition-type fade --transition-fps 60 --transition-duration 0.6 --resize crop; " +
      "AWWW_STATUS=$?; " +
      "if [ $AWWW_STATUS -eq 0 ]; then " +
      "  matugen image \"$1\" --source-color-index 0 --type scheme-tonal-spot; " +
      "  MATUGEN_STATUS=$?; " +
      "  mkdir -p \"$(dirname \"$STATE_FILE\")\"; " +
      "  printf '%s\\n' \"$1\" > \"$STATE_FILE\"; " +
      "  echo \"wallpaper_switcher: matugen exited with code $MATUGEN_STATUS\" >&2; " +
      "fi; " +
      "exit $AWWW_STATUS",
      "wallpaper-switcher",
      wallpaperPath
    ]

    onRunningChanged: {
      if (!running) {
        if (exitCode === 0) {
          console.log("wallpaper_switcher: applied, matugen ran, saved", wallpaperPath)
          root.closeRequested()
        } else {
          console.warn("wallpaper_switcher: awww exited with code", exitCode)
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim().length > 0)
          console.warn("wallpaper_switcher:", text.trim())
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      spacing: 5

      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 7
        Layout.rightMargin: 7

        Text {
          text: "Wallpaper"
          color: "#e8eaed"
          font {
            family: "SF Pro Display"
            pixelSize: 14
            weight: Font.DemiBold
          }
        }

        Item { Layout.fillWidth: true }

        Text {
          text: root.wallpapers.length > 0
                ? (root.currentIndex + 1) + "/" + root.wallpapers.length
                : "0/0"
          color: "#777777"
          font {
            family: "SF Pro Display"
            pixelSize: 11
          }
        }
      }

      ListView {
        id: wallpapersList

        Layout.fillWidth: true
        Layout.preferredHeight: root.cardHeight + 38
        Layout.leftMargin: root.sidePadding
        Layout.rightMargin: root.sidePadding
        clip: true
        orientation: ListView.Horizontal
        spacing: root.cardSpacing
        model: root.wallpapers
        currentIndex: root.currentIndex
        boundsBehavior: Flickable.StopAtBounds

        delegate: Item {
          id: wallpaperDelegate

          required property string modelData
          required property int index

          width: root.cardWidth
          height: root.cardHeight + 14

          readonly property bool selected: root.currentIndex === index

          // Keep the whole scaled card inside the ListView viewport.
          y: selected ? 2 : 5
          scale: selected ? root.selectedScale : 1.0
          transformOrigin: Item.Center
          z: selected ? 2 : 1

          Behavior on y {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
          }

          Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
          }

          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.cardHeight
            radius: root.imageRadius
            clip: true
            color: "#000000"
            border.width: wallpaperDelegate.selected ? 2 : 0
            border.color: "#80d4dc"

            Image {
              anchors.fill: parent
              source: "file://" + wallpaperDelegate.modelData
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              cache: true
            }

            Rectangle {
              anchors.fill: parent
              radius: root.imageRadius
              color: "#000000"
              opacity: wallpaperDelegate.selected ? 0.0 : 0.12
            }

            // Separate overlay keeps the selection border above the image
            // instead of letting the image paint over the border.
            Rectangle {
              anchors.fill: parent
              radius: root.imageRadius
              color: "transparent"
              border.width: wallpaperDelegate.selected ? 1 : 0
              border.color: "#80d4dc"
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: {
              root.currentIndex = wallpaperDelegate.index
              wallpapersList.positionViewAtIndex(wallpaperDelegate.index, ListView.Center)
            }

            onClicked: {
              root.currentIndex = wallpaperDelegate.index
              root.applyCurrent()
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: root.wallpapers.length === 0
          text: "No wallpapers found"
          color: "#666666"
          font {
            family: "SF Pro Display"
            pixelSize: 13
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 14
        Layout.rightMargin: 14

        Item { Layout.fillWidth: true }

        Text {
          text: "← / →  to cycle"
          color: "#666666"
          font { family: "SF Pro Display"; pixelSize: 10 }
        }

        Text {
          text: "Enter to apply"
          color: "#666666"
          font { family: "SF Pro Display"; pixelSize: 10 }
        }
      }
    }
  }

  Keys.onLeftPressed: function(event) {
    root.previous()
    event.accepted = true
  }

  Keys.onRightPressed: function(event) {
    root.next()
    event.accepted = true
  }

  Keys.onReturnPressed: function(event) {
    root.applyCurrent()
    event.accepted = true
  }

  Keys.onEscapePressed: function(event) {
    root.closeRequested()
    event.accepted = true
  }

  Component.onCompleted: {
    root.loadWallpapers()
    root.forceActiveFocus()
  }
}
