import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs

// Embedded inside the bar's pill. Only the PILL animates size — this
// component's own implicitHeight/preferredHeight change instantly,
// so there's a single source of animation instead of two chasing
// each other (that was the source of the jitter).
Item {
  id: root

  readonly property int rowHeight: 46
  readonly property int rowSpacing: 4
  readonly property int maxVisibleRows: 6
  readonly property int searchBarHeight: 60
  readonly property int sectionSpacing: 10
  readonly property int maxRecents: 6

  opacity: pill.isHovered ? 1 : 0

  Behavior on opacity {
    NumberAnimation { duration: 300; easing.type: Easing.OutQuad  }
  }

  clip: true

  property var apps: DesktopEntries.applications.values
  property string query: ""

  // recent app ids persisted to disk
  FileView {
    id: recentsFile
    path: Quickshell.stateDir + "/launcher-recents.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: recentsAdapter
      // Launch history is kept as a simple list so we can build a
      // frequency-based ranking without an extra data structure.
      property list<string> recentIds: []
    }
  }

  // An app only becomes a "recent" after being launched 5 times.
  // Before that, every launch gives it one more step up the normal list.
  readonly property int recentThreshold: 5

  function launchCount(id) {
    var count = 0
    for (var i = 0; i < recentsAdapter.recentIds.length; ++i) {
      if (recentsAdapter.recentIds[i] === id)
        ++count
    }
    return count
  }

  function recordRecent(id) {
    var list = recentsAdapter.recentIds.slice()
    list.push(id)

    // Keep enough history for ranking, while preventing the file from
    // growing forever. Counts older than this still behave sensibly.
    if (list.length > 100)
      list = list.slice(list.length - 100)

    recentsAdapter.recentIds = list
  }

  function rankedApps(source) {
    var ranked = source.slice()

    ranked.sort(function(a, b) {
      var countA = root.launchCount(a.id)
      var countB = root.launchCount(b.id)

      if (countA !== countB)
        return countB - countA

      // Stable-ish fallback: keep the desktop entry order when counts match.
      return 0
    })

    return ranked
  }

  // Freedesktop category -> words people actually type. Lets "browser"
  // find every app tagged WebBrowser, "editor" every TextEditor, etc.
  readonly property var categoryAliases: ({
    "WebBrowser": ["browser", "web", "internet"],
    "Network": ["network", "internet"],
    "Email": ["email", "mail"],
    "InstantMessaging": ["chat", "messenger", "messaging"],
    "Chat": ["chat", "messenger", "messaging"],
    "VideoConference": ["call", "meeting", "video"],
    "FileTransfer": ["download", "torrent", "transfer"],
    "P2P": ["torrent", "download"],
    "TerminalEmulator": ["terminal", "console", "shell"],
    "TextEditor": ["editor", "text"],
    "IDE": ["ide", "editor", "code", "dev"],
    "Development": ["dev", "development", "code", "programming"],
    "FileManager": ["files", "file manager", "explorer"],
    "FileTools": ["files"],
    "Audio": ["music", "audio", "sound"],
    "Music": ["music", "audio"],
    "Video": ["video", "movie", "media"],
    "Player": ["player", "media"],
    "AudioVideo": ["media", "multimedia"],
    "Graphics": ["graphics", "image", "photo", "art"],
    "Photography": ["photo", "camera"],
    "RasterGraphics": ["image", "photo"],
    "VectorGraphics": ["vector", "svg", "image"],
    "Office": ["office", "document"],
    "WordProcessor": ["word", "document", "writer"],
    "Spreadsheet": ["spreadsheet", "sheet", "excel"],
    "Presentation": ["slides", "presentation"],
    "Viewer": ["viewer", "pdf", "reader"],
    "Game": ["game", "games", "gaming"],
    "Settings": ["settings", "preferences", "config"],
    "System": ["system"],
    "Monitor": ["monitor", "task manager", "resources"],
    "Utility": ["utility", "tool", "tools"],
    "Calculator": ["calculator", "calc"],
    "Science": ["science"],
    "Education": ["education", "learn"]
  })

  // Everything searchable about an app, lowercased, for type-based matching:
  // generic name ("Web Browser"), keywords, and categories + their aliases.
  function typeHaystack(app) {
    var parts = []
    if (app.genericName) parts.push(app.genericName)
    if (app.keywords) {
      for (var i = 0; i < app.keywords.length; ++i)
        parts.push(app.keywords[i])
    }
    if (app.categories) {
      for (var j = 0; j < app.categories.length; ++j) {
        var c = app.categories[j]
        parts.push(c)
        var al = root.categoryAliases[c]
        if (al) parts = parts.concat(al)
      }
    }
    return parts.join(" | ").toLowerCase()
  }

  // Label shown next to each app. Uses the app's own GenericName when it
  // defines one, otherwise falls back to its most specific category.
  // Ordered specific -> generic so "WebBrowser" wins over "Network".
  readonly property var categoryLabels: [
    ["WebBrowser", "Web Browser"], ["Email", "Email Client"],
    ["InstantMessaging", "Messenger"], ["Chat", "Messenger"],
    ["VideoConference", "Video Call"], ["P2P", "Torrent Client"],
    ["FileTransfer", "File Transfer"], ["TerminalEmulator", "Terminal"],
    ["TextEditor", "Text Editor"], ["IDE", "Code Editor"],
    ["FileManager", "File Manager"], ["Calculator", "Calculator"],
    ["Monitor", "System Monitor"], ["WordProcessor", "Word Processor"],
    ["Spreadsheet", "Spreadsheet"], ["Presentation", "Presentation"],
    ["Office", "Office"], ["Music", "Music Player"], ["Player", "Media Player"],
    ["Video", "Video"], ["Audio", "Audio"], ["AudioVideo", "Multimedia"],
    ["RasterGraphics", "Image Editor"], ["VectorGraphics", "Vector Graphics"],
    ["Photography", "Photography"], ["Viewer", "Viewer"], ["Graphics", "Graphics"],
    ["Game", "Game"], ["Development", "Development"], ["Settings", "Settings"],
    ["System", "System"], ["Network", "Network"], ["Utility", "Utility"],
    ["Science", "Science"], ["Education", "Education"]
  ]

  function typeLabel(app) {
    if (app.genericName && app.genericName.length > 0)
      return app.genericName
    if (!app.categories) return ""
    for (var i = 0; i < root.categoryLabels.length; ++i) {
      if (app.categories.indexOf(root.categoryLabels[i][0]) !== -1)
        return root.categoryLabels[i][1]
    }
    return ""
  }

  // 3 = name starts with query, 2 = name contains it, 1 = matches app type, 0 = no match
  function matchScore(app, q) {
    var name = app.name.toLowerCase()
    if (name.startsWith(q)) return 3
    if (name.includes(q)) return 2
    if (root.typeHaystack(app).includes(q)) return 1
    return 0
  }

  function searchApps(q) {
    q = q.trim().toLowerCase()
    var scored = []
    for (var i = 0; i < apps.length; ++i) {
      var sc = root.matchScore(apps[i], q)
      if (sc > 0) scored.push({ app: apps[i], score: sc })
    }
    scored.sort(function(a, b) {
      if (a.score !== b.score) return b.score - a.score
      return root.launchCount(b.app.id) - root.launchCount(a.app.id)
    })
    return scored.map(x => x.app)
  }

  property var recentApps: apps
      .filter(a => root.launchCount(a.id) >= root.recentThreshold)
      .sort((a, b) => root.launchCount(b.id) - root.launchCount(a.id))
      .slice(0, root.maxRecents)

  property bool showingRecents: query.length === 0 && recentApps.length > 0

  property var displayApps: {
    if (query.length > 0) {
      return root.searchApps(query)
    }

    var ranked = root.rankedApps(apps)

    // Recents are only the apps that reached 5 launches. They stay in
    // their own section at the top; everything else remains below them.
    if (recentApps.length === 0)
      return ranked

    var recentIds = recentApps.map(a => a.id)
    var rest = ranked.filter(a => recentIds.indexOf(a.id) === -1)
    return recentApps.concat(rest)
  }

  readonly property int visibleRows: Math.max(1, Math.min(displayApps.length, maxVisibleRows))
  readonly property real listHeight: displayApps.length === 0
      ? rowHeight
      : visibleRows * rowHeight + (visibleRows - 1) * rowSpacing

  implicitWidth: 480
  implicitHeight: searchBarHeight + sectionSpacing + listHeight
      + (showingRecents && recentApps.length > 0 ? headerLabel.implicitHeight + 4 : 0)

  // background pill sizes itself instantly off implicitWidth/implicitHeight
  // above (unaffected by this) — only the visible content fades in, and
  // only once the pill's resize has had time to settle, so you don't see
  // both animating on top of each other
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

  signal closeRequested()

  function launch(entry) {
    recordRecent(entry.id)
    entry.execute()
    root.closeRequested()
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: root.sectionSpacing

    // search bar — stays first/top always, never moves
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.searchBarHeight
      radius: 99
      color: "#000000"
      Text {
        text: ""
        color: "#e8eaed"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenterOffset: -210
        anchors.verticalCenterOffset: -5

        Behavior on anchors.horizontalCenterOffset {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        font {
            pixelSize: 18
            weight: 600
        }
      }

      Rectangle {
        implicitHeight: 0.6
        radius: 16
        implicitWidth: 450
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 20
      }

      TextInput {
        id: searchInput
        anchors.fill: parent
        anchors.leftMargin: 40
        anchors.rightMargin: 14
        anchors.bottomMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        focus: true
        color: "#e8eaed"
        font {
          family: "SF Pro Display"
          pixelSize: 15
        }

        onTextChanged: {
          root.query = text
          resultsList.currentIndex = 0
        }

        Keys.onEscapePressed: root.closeRequested()
        Keys.onReturnPressed: {
          var index = resultsList.currentIndex
          if (index >= 0 && index < root.displayApps.length)
            root.launch(root.displayApps[index])
        }
        Keys.onDownPressed: {
          resultsList.incrementCurrentIndex()
          resultsList.positionViewAtIndex(resultsList.currentIndex, ListView.Contain)
        }
        Keys.onUpPressed: {
          resultsList.decrementCurrentIndex()
          resultsList.positionViewAtIndex(resultsList.currentIndex, ListView.Contain)
        }
      }
    }

    ListView {
      id: resultsList
      Layout.fillWidth: true
      Layout.preferredHeight: root.listHeight
      clip: true
      spacing: root.rowSpacing
      model: root.displayApps
      currentIndex: 0
      highlightMoveDuration: 100

      Text {
        anchors.centerIn: parent
        visible: resultsList.count === 0
        text: "Nothing Found"
        color: "#666666"
        font.pixelSize: 14
      }

      delegate: Rectangle {
        id: entryDelegate
        required property var modelData
        required property int index

        width: resultsList.width
        implicitHeight: root.rowHeight
        radius: 12
        color: resultsList.currentIndex === index ? "#313036" : "transparent"

        Rectangle {
          implicitWidth: resultsList.currentIndex === index ? 4 : 0
          implicitHeight: resultsList.currentIndex === index ? 20 : 0
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

        Behavior on color {
          ColorAnimation { duration: 100 }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 10

          IconImage {
            implicitWidth: 24
            implicitHeight: 24
            source: Quickshell.iconPath(entryDelegate.modelData.icon, "application-x-executable")
          }

          Text {
            Layout.fillWidth: true
            text: entryDelegate.modelData.name
            color: "#e8eaed"
            elide: Text.ElideRight
            font {
              family: "SF Pro Display"
              pixelSize: 14
            }
          }

          Text {
            text: root.typeLabel(entryDelegate.modelData)
            visible: text.length > 0
            color: "#7d8087"
            elide: Text.ElideRight
            Layout.maximumWidth: 150
            horizontalAlignment: Text.AlignRight
            font {
              family: "SF Pro Display"
              pixelSize: 12
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          onEntered: resultsList.currentIndex = entryDelegate.index
          onClicked: root.launch(entryDelegate.modelData)
        }
      }
    }
  }

  Component.onCompleted: searchInput.forceActiveFocus()
}
