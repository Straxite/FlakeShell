import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs

// Launcher embedded in the bar's pill.
//
// Like ControlPanel, nothing is shown half-loaded: history is read
// synchronously, the first rows' icons must finish loading, and the pill's
// resize must have settled. Only then does the content fade in, all at once.
//
// Search bar tricks:
//   text      fuzzy app search (name, keywords, categories, "browser", "editor"...)
//   2+2*3     calculator, Enter copies the result
//   > cmd     run a shell command
//   ? text    web search (a link like www.x.com or https://... just opens)
//   Tab       complete the selected app's name
//   Alt+1..9  launch the Nth visible row
Item {
  id: root

  signal closeRequested()

  // ---------- sizes ----------
  readonly property int rowHeight: 46
  readonly property int rowSpacing: 4
  readonly property int maxVisibleRows: 6
  readonly property int searchBarHeight: 60
  readonly property int sectionSpacing: 10
  readonly property int recentThreshold: 5   // launches before an app counts as "recent"
  readonly property int maxRecents: 6

  readonly property int visibleRows: Math.max(1, Math.min(results.length, maxVisibleRows))
  readonly property real listHeight: visibleRows * rowHeight + (visibleRows - 1) * rowSpacing

  implicitWidth: 480
  implicitHeight: searchBarHeight + sectionSpacing + listHeight
  clip: true

  // ---------- load gate ----------
  // `ready` flips once everything is loaded. The pill can read it too.
  property bool settled: false      // pill resize has had time to settle
  property bool iconsLoaded: false  // first visible rows have their icons
  readonly property bool ready: settled && iconsLoaded

  Timer { interval: 120; running: true; onTriggered: root.settled = true }
  // Safety net so a broken icon can never keep the launcher hidden.
  Timer { interval: 400; running: true; onTriggered: root.iconsLoaded = true }

  function checkIcons() {
    if (iconsLoaded) return
    for (var i = 0; i < visibleRows; ++i) {
      var row = list.itemAtIndex(i)
      if (!row || !row.iconReady) return
    }
    iconsLoaded = true
  }

  // ---------- launch history ----------
  FileView {
    path: Quickshell.stateDir + "/launcher-recents.json"
    blockLoading: true   // read before the first frame, not after
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: recents
      property list<string> recentIds: []
    }
  }

  // id -> number of launches
  readonly property var counts: {
    var m = {}
    for (var i = 0; i < recents.recentIds.length; ++i) {
      var id = recents.recentIds[i]
      m[id] = (m[id] || 0) + 1
    }
    return m
  }

  function recordLaunch(id) {
    var l = recents.recentIds.slice()
    l.push(id)
    if (l.length > 100) l = l.slice(l.length - 100)
    recents.recentIds = l
  }

  function byUsage(a, b) {
    return (counts[b.id] || 0) - (counts[a.id] || 0) || a.name.localeCompare(b.name)
  }

  // ---------- app types ----------
  // category -> [label shown in the row, extra words people type]
  // Ordered specific -> generic so "WebBrowser" labels before "Network".
  readonly property var types: ({
    "WebBrowser": ["Web Browser", "browser", "web", "internet"],
    "Email": ["Email Client", "email", "mail"],
    "InstantMessaging": ["Messenger", "chat", "messaging"],
    "Chat": ["Messenger", "chat", "messaging"],
    "VideoConference": ["Video Call", "call", "meeting", "video"],
    "P2P": ["Torrent Client", "torrent", "download"],
    "FileTransfer": ["File Transfer", "download", "transfer"],
    "TerminalEmulator": ["Terminal", "console", "shell"],
    "TextEditor": ["Text Editor", "editor", "text"],
    "IDE": ["Code Editor", "ide", "editor", "code", "dev"],
    "FileManager": ["File Manager", "files", "explorer"],
    "FileTools": ["File Tools", "files"],
    "Calculator": ["Calculator", "calc"],
    "Monitor": ["System Monitor", "task manager", "resources"],
    "WordProcessor": ["Word Processor", "word", "document", "writer"],
    "Spreadsheet": ["Spreadsheet", "sheet", "excel"],
    "Presentation": ["Presentation", "slides"],
    "Office": ["Office", "document"],
    "Music": ["Music Player", "music", "audio"],
    "Player": ["Media Player", "player", "media"],
    "Video": ["Video", "movie", "media"],
    "Audio": ["Audio", "music", "sound"],
    "AudioVideo": ["Multimedia", "media", "multimedia"],
    "RasterGraphics": ["Image Editor", "image", "photo"],
    "VectorGraphics": ["Vector Graphics", "vector", "svg", "image"],
    "Photography": ["Photography", "photo", "camera"],
    "Viewer": ["Viewer", "viewer", "pdf", "reader"],
    "Graphics": ["Graphics", "image", "art"],
    "Game": ["Game", "games", "gaming"],
    "Development": ["Development", "dev", "code", "programming"],
    "Settings": ["Settings", "preferences", "config"],
    "System": ["System", "system"],
    "Network": ["Network", "internet"],
    "Utility": ["Utility", "tool", "tools"],
    "Science": ["Science", "science"],
    "Education": ["Education", "learn"]
  })

  // Label shown on the right: the app's own GenericName, else its first known category.
  function typeLabel(app) {
    if (app.genericName) return app.genericName
    for (var key in types)
      if (app.categories && app.categories.indexOf(key) !== -1) return types[key][0]
    return ""
  }

  // Everything searchable about an app besides its name, lowercased.
  function typeText(app) {
    var t = [app.genericName, app.comment, app.id]
    for (var i = 0; app.keywords && i < app.keywords.length; ++i) t.push(app.keywords[i])
    for (var j = 0; app.categories && j < app.categories.length; ++j) {
      var c = app.categories[j]
      t.push(c)
      if (types[c]) t = t.concat(types[c])
    }
    return t.join(" | ").toLowerCase()
  }

  // ---------- apps + search ----------
  readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)

  // built once per app list, not once per keystroke
  readonly property var haystack: {
    var m = {}
    apps.forEach(a => m[a.id] = typeText(a))
    return m
  }

  // true if the letters of q appear in s in order ("ffx" -> "firefox")
  function fuzzy(q, s) {
    var i = 0
    for (var j = 0; j < s.length && i < q.length; ++j)
      if (s[j] === q[i]) ++i
    return i === q.length
  }

  function score(app, q) {
    var name = app.name.toLowerCase()
    if (name === q) return 100
    if (name.startsWith(q)) return 90
    if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 80
    if (name.includes(q)) return 70
    if (haystack[app.id].includes(q)) return 50
    if (q.length > 1 && fuzzy(q, name)) return 30
    return 0
  }

  // ---------- extras: calculator, shell, web ----------
  function calc(q) {
    var expr = q.replace(/^=/, "").replace(/\^/g, "**")
    // digits and operators only, and at least one real operation
    if (!/^[0-9+\-*\/().%\s]+$/.test(expr)) return null
    if (!/[\d)]\s*[-+*\/%]+\s*[\d(.]/.test(expr)) return null
    try {
      var r = Function('"use strict"; return (' + expr + ')')()
      return (typeof r === "number" && isFinite(r)) ? Math.round(r * 1e10) / 1e10 : null
    } catch (e) {
      return null
    }
  }

  function appItem(app, recent) {
    var label = typeLabel(app)
    return {
      id: app.id,
      title: app.name,
      sub: recent ? (label ? "Recent · " + label : "Recent") : label,
      icon: app.icon,
      run: () => app.execute()
    }
  }

  function extraItem(title, sub, icon, cmd) {
    return { id: "", title: title, sub: sub, icon: icon, run: () => Quickshell.execDetached(cmd) }
  }

  function webItem(s) {
    var isLink = /^(https?:\/\/|www\.)\S+$/.test(s)
    var url = !isLink ? "https://duckduckgo.com/?q=" + encodeURIComponent(s)
                      : (s.startsWith("www.") ? "https://" + s : s)
    return extraItem(isLink ? "Open " + s : 'Search the web for "' + s + '"',
                     isLink ? "Link" : "Web search", "web-browser", ["xdg-open", url])
  }

  // ---------- the list the user sees ----------
  property string query: ""
  readonly property var results: buildResults(query)

  function buildResults(raw) {
    var q = raw.trim()

    if (q.startsWith(">")) {
      var cmd = q.slice(1).trim()
      return cmd ? [extraItem("Run: " + cmd, "Shell command", "utilities-terminal", ["sh", "-c", cmd])] : []
    }
    if (q.startsWith("?")) {
      var s = q.slice(1).trim()
      return s ? [webItem(s)] : []
    }

    // no query: frequent apps first (the "Recent" ones), then everything else
    if (q.length === 0) {
      var sorted = apps.slice().sort(byUsage)
      var frequent = sorted.filter(a => (counts[a.id] || 0) >= recentThreshold).slice(0, maxRecents)
      var rest = sorted.filter(a => frequent.indexOf(a) === -1)
      return frequent.map(a => appItem(a, true)).concat(rest.map(a => appItem(a, false)))
    }

    var out = []
    var math = calc(q)
    if (math !== null)
      out.push({
        id: "", title: "= " + math, sub: q + " · Enter to copy", icon: "accessories-calculator",
        run: () => Quickshell.execDetached(["wl-copy", String(math)])
      })

    var lq = q.toLowerCase()
    var scored = []
    apps.forEach(a => {
      var sc = score(a, lq)
      if (sc > 0) scored.push({ app: a, score: sc })
    })
    scored.sort((a, b) => (b.score - a.score) || byUsage(a.app, b.app))

    return out.concat(scored.map(x => appItem(x.app, false))).concat([webItem(q)])
  }

  function launchAt(i) {
    var item = results[i]
    if (!item) return
    if (item.id) recordLaunch(item.id)
    item.run()
    closeRequested()
  }

  // ---------- UI ----------
  ColumnLayout {
    anchors.fill: parent
    spacing: root.sectionSpacing

    opacity: root.ready ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

    // search bar
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.searchBarHeight
      radius: 99
      color: "#000000"

      Text {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        text: "\uf002"
        color: "#7d8087"
        font.pixelSize: 16
      }
    Rectangle {
        implicitHeight: 2
        implicitWidth: 460
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 26
        opacity: 0.2
    }

      TextInput {
        id: searchInput
        anchors.fill: parent
        anchors.leftMargin: 50
        anchors.rightMargin: 20
        verticalAlignment: TextInput.AlignVCenter
        focus: true
        color: "#e8eaed"
        selectionColor: Colors.primary
        font { family: "SF Pro Display"; pixelSize: 15 }

        Text {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          visible: searchInput.text.length === 0
          text: "Search apps   = math   > command   ? web"
          color: "#5f6368"
          font: searchInput.font
        }

        onTextChanged: {
          root.query = text
          list.currentIndex = 0
          list.positionViewAtBeginning()
        }

        Keys.onPressed: (e) => {
          var ctrl = e.modifiers & Qt.ControlModifier
          var alt = e.modifiers & Qt.AltModifier
          var handled = true

          if (e.key === Qt.Key_Escape) {
            if (text.length > 0) clear()
            else root.closeRequested()
          }
          else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) root.launchAt(list.currentIndex)
          else if (e.key === Qt.Key_Down || (ctrl && (e.key === Qt.Key_N || e.key === Qt.Key_J))) list.incrementCurrentIndex()
          else if (e.key === Qt.Key_Up || (ctrl && (e.key === Qt.Key_P || e.key === Qt.Key_K))) list.decrementCurrentIndex()
          else if (e.key === Qt.Key_PageDown) list.currentIndex = Math.min(list.count - 1, list.currentIndex + root.maxVisibleRows)
          else if (e.key === Qt.Key_PageUp) list.currentIndex = Math.max(0, list.currentIndex - root.maxVisibleRows)
          else if (e.key === Qt.Key_Tab) {
            var item = root.results[list.currentIndex]
            if (item && item.id) {
              text = item.title
              cursorPosition = text.length
            }
          }
          else if (alt && e.key >= Qt.Key_1 && e.key <= Qt.Key_9)
            root.launchAt(list.indexAt(0, list.contentY + 1) + (e.key - Qt.Key_1))
          else handled = false

          e.accepted = handled
        }
      }
    }

    // results
    ListView {
      id: list
      Layout.fillWidth: true
      Layout.preferredHeight: root.listHeight
      clip: true
      spacing: root.rowSpacing
      model: root.results
      currentIndex: 0
      keyNavigationWraps: true
      highlightMoveDuration: 100
      onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

      Text {
        anchors.centerIn: parent
        visible: list.count === 0
        text: "Nothing found"
        color: "#666666"
        font.pixelSize: 14
      }

      delegate: Rectangle {
        id: row
        required property var modelData
        required property int index

        readonly property bool selected: ListView.isCurrentItem
        // true once the icon is loaded (or failed, which also counts as done)
        readonly property bool iconReady: icon.status !== Image.Loading
        onIconReadyChanged: root.checkIcons()
        Component.onCompleted: root.checkIcons()

        width: list.width
        implicitHeight: root.rowHeight
        radius: 12
        color: selected ? "#313036" : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }

        // accent bar on the selected row
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: row.selected ? 4 : 0
          height: row.selected ? 20 : 0
          radius: 2
          color: Colors.primary
          Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
          Behavior on height { NumberAnimation { duration: 100 } }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 10

          IconImage {
            id: icon
            implicitWidth: 24
            implicitHeight: 24
            source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
          }

          Text {
            Layout.fillWidth: true
            text: row.modelData.title
            color: "#e8eaed"
            elide: Text.ElideRight
            font { family: "SF Pro Display"; pixelSize: 14 }
          }

          Text {
            visible: text.length > 0
            text: row.modelData.sub
            color: "#7d8087"
            elide: Text.ElideRight
            Layout.maximumWidth: 170
            horizontalAlignment: Text.AlignRight
            font { family: "SF Pro Display"; pixelSize: 12 }
          }
        }

        MouseArea {
          anchors.fill: parent
          hoverEnabled: true
          // positionChanged, not entered: scrolling under a still mouse won't steal the selection
          onPositionChanged: list.currentIndex = row.index
          onClicked: root.launchAt(row.index)
        }
      }
    }
  }

  Component.onCompleted: searchInput.forceActiveFocus()
}
