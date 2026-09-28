import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Embedded inside the bar's pill. Only the PILL animates size — this
// component's own implicitHeight/preferredHeight change instantly,
// so there's a single source of animation instead of two chasing
// each other (that was the source of the jitter).
Item {
  id: root

  readonly property int rowHeight: 46
  readonly property int rowSpacing: 4
  readonly property int maxVisibleRows: 6
  readonly property int searchBarHeight: 40
  readonly property int sectionSpacing: 10
  readonly property int maxRecents: 6

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

  property var recentApps: apps
      .filter(a => root.launchCount(a.id) >= root.recentThreshold)
      .sort((a, b) => root.launchCount(b.id) - root.launchCount(a.id))
      .slice(0, root.maxRecents)

  property bool showingRecents: query.length === 0 && recentApps.length > 0

  property var displayApps: {
    if (query.length > 0) {
      var filtered = apps.filter(a =>
        a.name.toLowerCase().includes(query.toLowerCase()))
      return root.rankedApps(filtered)
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

  implicitWidth: 420
  implicitHeight: searchBarHeight + sectionSpacing + listHeight
      + (showingRecents && recentApps.length > 0 ? headerLabel.implicitHeight + 4 : 0)

  // background pill sizes itself instantly off implicitWidth/implicitHeight
  // above (unaffected by this) — only the visible content fades in, and
  // only once the pill's resize has had time to settle, so you don't see
  // both animating on top of each other
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
      color: "#1a1a1a"

      TextInput {
        id: searchInput
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
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

    Text {
      id: headerLabel
      visible: root.showingRecents && root.recentApps.length > 0
      text: " Bonjourr User!"
      color: "#666666"
      font {
        family: "SF Pro Display"
        pixelSize: 11
        capitalization: Font.AllUppercase
        letterSpacing: 1
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
        text: "no results"
        color: "#666666"
        font.pixelSize: 14
      }

      delegate: Rectangle {
        id: entryDelegate
        required property var modelData
        required property int index

        width: resultsList.width
        implicitHeight: root.rowHeight
        radius: 99
        color: resultsList.currentIndex === index ? "#80d4dc" : "transparent"

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
