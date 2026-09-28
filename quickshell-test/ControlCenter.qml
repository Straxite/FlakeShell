import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris

Item {
  id: root
  implicitWidth: 460
  implicitHeight: 400

  signal closeRequested()

  property string view: "main"   // main | network | bluetooth | notifications

  opacity: 0
  Behavior on opacity {
    NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
  }
  Timer {
    interval: 110
    running: true
    repeat: false
    onTriggered: root.opacity = 1
  }

  // ---------- reusable pieces ----------

  component StatusCard: Rectangle {
    id: card
    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property var onToggle: function() {}
    property var onExpand: function() {}

    radius: 16
    color: "#1a1a1a"

    MouseArea {
      anchors.fill: parent
      onClicked: card.onToggle()
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 122
      anchors.rightMargin: 8
      spacing: 10

      Rectangle {
        implicitWidth: 34
        implicitHeight: 34
        radius: 17
        color: card.active ? "#7ecfff" : "#333333"

        Behavior on color {
          ColorAnimation { duration: 150 }
        }

        IconImage {
          anchors.centerIn: parent
          implicitWidth: 17
          implicitHeight: 17
          source: Quickshell.iconPath(card.iconName, card.iconName)
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          text: card.title
          color: "#e8eaed"
          font {
            family: "SF Pro Display"
            pixelSize: 13
            weight: Font.DemiBold
          }
        }

        Text {
          text: card.subtitle
          color: "#888888"
          elide: Text.ElideRight
          Layout.fillWidth: true
          font {
            family: "SF Pro Display"
            pixelSize: 11
          }
        }
      }

      Rectangle {
        implicitWidth: 24
        implicitHeight: 24
        radius: 12
        color: "#ffffff18"

        Text {
          anchors.centerIn: parent
          anchors.horizontalCenterOffset: 1
          text: "\u203A"
          color: "#cccccc"
          font.pixelSize: 15
        }

        MouseArea {
          anchors.fill: parent
          onClicked: card.onExpand()
        }
      }
    }
  }

  component SliderCard: Rectangle {
    id: sliderCard
    property string iconName: ""
    property real value: 0
    property var onCommit: function(v) {}

    implicitHeight: 40
    radius: 20
    color: "#1a1a1a"
    clip: true

    Rectangle {
      width: parent.width * Math.max(0, Math.min(100, sliderCard.value)) / 100
      height: parent.height
      radius: 20
      color: "#7ecfff"

      Behavior on width {
        enabled: !dragArea.pressed
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
      }
    }

    IconImage {
      anchors.left: parent.left
      anchors.leftMargin: 12
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: 15
      implicitHeight: 15
      source: Quickshell.iconPath(sliderCard.iconName, sliderCard.iconName)
    }

    MouseArea {
      id: dragArea
      anchors.fill: parent

      function updateFromX(x) {
        var v = Math.max(0, Math.min(100, (x / width) * 100))
        sliderCard.value = v
        sliderCard.onCommit(v)
      }

      onPressed: (mouse) => updateFromX(mouse.x)
      onPositionChanged: (mouse) => { if (pressed) updateFromX(mouse.x) }
    }
  }

  component NowPlayingCard: Rectangle {
    id: npCard
    radius: 16
    color: "#1a1a1a"
    clip: true

    readonly property var activePlayer: {
      var players = Mpris.players.values
      for (var i = 0; i < players.length; i++) {
        if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
      }
      return players.length > 0 ? players[0] : null
    }
    readonly property bool hasMedia: activePlayer !== null
    readonly property string artUrl: hasMedia ? activePlayer.trackArtUrl : ""

    Image {
      anchors.fill: parent
      visible: npCard.artUrl.length > 0
      source: npCard.artUrl
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }

    Rectangle {
      anchors.fill: parent
      color: "#000000"
      opacity: npCard.artUrl.length > 0 ? 0.5 : 0
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 4

      Text {
        Layout.fillWidth: true
        text: npCard.hasMedia ? (npCard.activePlayer.trackTitle || "Unknown Title") : "Not playing"
        color: "#e8eaed"
        elide: Text.ElideRight
        font {
          family: "SF Pro Display"
          pixelSize: 13
          weight: Font.DemiBold
        }
      }

      Text {
        Layout.fillWidth: true
        visible: npCard.hasMedia && npCard.activePlayer.trackArtist.length > 0
        text: npCard.hasMedia ? npCard.activePlayer.trackArtist : ""
        color: "#cccccc"
        elide: Text.ElideRight
        font {
          family: "SF Pro Display"
          pixelSize: 11
        }
      }

      Item { Layout.fillHeight: true }

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 20

        Text {
          text: "\u23EE"
          color: "#e8eaed"
          font.pixelSize: 15
          opacity: npCard.hasMedia ? 1 : 0.35
          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: npCard.hasMedia
            onClicked: npCard.activePlayer.previous()
          }
        }

        Rectangle {
          implicitWidth: 30
          implicitHeight: 30
          radius: 15
          color: "#7ecfff"
          opacity: npCard.hasMedia ? 1 : 0.35

          Text {
            anchors.centerIn: parent
            text: npCard.hasMedia && npCard.activePlayer.isPlaying ? "\u23F8" : "\u25B6"
            color: "#0a0a0a"
            font.pixelSize: 13
          }

          MouseArea {
            anchors.fill: parent
            enabled: npCard.hasMedia
            onClicked: npCard.activePlayer.togglePlaying()
          }
        }

        Text {
          text: "\u23ED"
          color: "#e8eaed"
          font.pixelSize: 15
          opacity: npCard.hasMedia ? 1 : 0.35
          MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            enabled: npCard.hasMedia
            onClicked: npCard.activePlayer.next()
          }
        }
      }
    }
  }

  // ---------- live status polling (nmcli / bluetoothctl / brightnessctl / wpctl) ----------

  property bool wifiOn: false
  property string wifiNetwork: ""
  property bool btOn: false
  property string btDevice: ""
  property real brightnessValue: 50
  property real volumeValue: 50

  function refreshStatus() {
    wifiStatus.running = true
    btStatus.running = true
    brightnessRead.running = true
    volumeRead.running = true
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshStatus()
  }

  Process {
    id: wifiStatus
    command: ["bash", "-lc",
      "echo \"$(nmcli radio wifi 2>/dev/null)\"; nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | head -1 | cut -d: -f2"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n")
        root.wifiOn = (lines[0] || "").trim() === "enabled"
        root.wifiNetwork = lines.length > 1 ? lines[1].trim() : ""
      }
    }
  }

  Process {
    id: btStatus
    command: ["bash", "-lc",
      "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off; " +
      "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n")
        root.btOn = (lines[0] || "").trim() === "on"
        root.btDevice = lines.length > 1 ? lines[1].trim() : ""
      }
    }
  }

  Process {
    id: brightnessRead
    command: ["bash", "-lc", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'"]
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseInt(text.trim())
        if (!isNaN(v)) root.brightnessValue = v
      }
    }
  }

  Process {
    id: volumeRead
    command: ["bash", "-lc", "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -oE '[0-9]+\\.[0-9]+' | head -1"]
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseFloat(text.trim())
        if (!isNaN(v)) root.volumeValue = Math.round(v * 100)
      }
    }
  }

  Process {
    id: wifiToggle
    property bool target: true
    command: ["bash", "-lc", "nmcli radio wifi $1", "control-center", target ? "on" : "off"]
    onRunningChanged: if (!running) root.refreshStatus()
  }

  Process {
    id: btToggle
    property bool target: true
    command: ["bash", "-lc", "bluetoothctl power $1", "control-center", target ? "on" : "off"]
    onRunningChanged: if (!running) root.refreshStatus()
  }

  Process {
    id: brightnessSet
    property real target: 50
    command: ["bash", "-lc", "brightnessctl set $1% -q", "control-center", target.toFixed(0) + ""]
  }

  Process {
    id: volumeSet
    property real target: 50
    command: ["bash", "-lc", "wpctl set-volume @DEFAULT_AUDIO_SINK@ $1%", "control-center", target.toFixed(0) + ""]
  }

  Timer {
    id: brightnessDebounce
    interval: 120
    repeat: false
    onTriggered: { brightnessSet.target = root.brightnessValue; brightnessSet.running = true }
  }

  Timer {
    id: volumeDebounce
    interval: 120
    repeat: false
    onTriggered: { volumeSet.target = root.volumeValue; volumeSet.running = true }
  }

  // ---------- layout ----------

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 10
    visible: root.view === "main"

    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      ColumnLayout {
        Layout.preferredWidth: 210
        spacing: 8

        StatusCard {
          Layout.fillWidth: true
          Layout.preferredHeight: 62
          iconName: "network-wireless-symbolic"
          title: "Wi-Fi"
          subtitle: root.wifiOn ? (root.wifiNetwork.length > 0 ? root.wifiNetwork : "On") : "Off"
          active: root.wifiOn
          onToggle: () => { wifiToggle.target = !root.wifiOn; wifiToggle.running = true }
          onExpand: () => { root.view = "network" }
        }

        StatusCard {
          Layout.fillWidth: true
          Layout.preferredHeight: 62
          iconName: "bluetooth-active-symbolic"
          title: "Bluetooth"
          subtitle: root.btOn ? (root.btDevice.length > 0 ? root.btDevice : "On") : "Off"
          active: root.btOn
          onToggle: () => { btToggle.target = !root.btOn; btToggle.running = true }
          onExpand: () => { root.view = "bluetooth" }
        }
      }

      NowPlayingCard {
        Layout.fillWidth: true
        Layout.preferredHeight: 132
      }
    }

    SliderCard {
      Layout.fillWidth: true
      iconName: "display-brightness-symbolic"
      value: root.brightnessValue
      onCommit: (v) => { root.brightnessValue = v; brightnessDebounce.restart() }
    }

    SliderCard {
      Layout.fillWidth: true
      iconName: "audio-volume-high-symbolic"
      value: root.volumeValue
      onCommit: (v) => { root.volumeValue = v; volumeDebounce.restart() }
    }

    StatusCard {
      Layout.fillWidth: true
      Layout.preferredHeight: 48
      iconName: "preferences-system-notifications-symbolic"
      title: "Notifications"
      subtitle: ""
      active: false
      onToggle: () => { root.view = "notifications" }
      onExpand: () => { root.view = "notifications" }
    }
  }

  // sub-panels — separate files, swapped in over the main grid
  Loader {
    id: subLoader
    anchors.fill: parent
    active: root.view !== "main"
    visible: root.view !== "main"
    source: root.view === "network" ? "NetworkPanel.qml"
      : root.view === "bluetooth" ? "BluetoothPanel.qml"
      : root.view === "notifications" ? "NotificationPanel.qml"
      : ""

    onLoaded: {
      item.back.connect(function() { root.view = "main" })
      item.closeRequested.connect(function() { root.closeRequested() })
    }
  }

  Keys.onEscapePressed: {
    if (root.view !== "main") root.view = "main"
    else root.closeRequested()
  }

  Component.onCompleted: {
    root.refreshStatus()
    root.forceActiveFocus()
  }
}
