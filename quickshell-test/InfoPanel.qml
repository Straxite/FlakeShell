import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

// Hover-revealed island: now-playing on the left, clock/date centered,
// wifi + battery on the right. Loaded into the pill on hover only —
// see shell.qml's infoHover HoverHandler.
Item {
  id: root

  property int imageRadius: 12

  implicitWidth: 580
  implicitHeight: 100

  // same "background settles first, content fades in after" pattern
  // used by the launcher and wallpaper switcher
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

  // prefer a player that's actually playing; fall back to whatever's
  // first so paused/stale sessions still show something
  readonly property var activePlayer: {
    var players = Mpris.players.values
    for (var i = 0; i < players.length; i++) {
      if (players[i].playbackState === MprisPlaybackState.Playing)
        return players[i]
    }
    return players.length > 0 ? players[0] : null
  }

  readonly property bool hasMedia: activePlayer !== null
  readonly property string trackTitle: hasMedia ? (activePlayer.trackTitle || "Unknown Title") : "Not playing"
  readonly property string trackArtist: hasMedia ? activePlayer.trackArtist : ""
  readonly property string trackArt: hasMedia ? activePlayer.trackArtUrl : ""

  // battery — real UPower service. percentage is a 0.0-1.0 fraction.
  readonly property real batteryPct: UPower.displayDevice.ready ? UPower.displayDevice.percentage * 100 : 0
  readonly property bool batteryCharging: UPower.displayDevice.state === UPowerDeviceState.Charging

  // wifi — polled via nmcli rather than the Networking API, kept
  // deliberately simple/version-light. Adjust the command below if
  // your distro's nmcli output differs.
  property bool wifiConnected: false

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: wifiCheck.running = true
  }

  Process {
    id: wifiCheck
    command: ["bash", "-lc", "nmcli -t -f STATE g 2>/dev/null || echo unknown"]
    stdout: StdioCollector {
      onStreamFinished: root.wifiConnected = text.trim() === "connected"
    }
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 18
    anchors.rightMargin: 18
    spacing: 18

    // now playing
    RowLayout {
      Layout.alignment: Qt.AlignVCenter
      spacing: 10

      Rectangle {
        implicitWidth: 38
        implicitHeight: 38
        radius: root.imageRadius
        color: "#1a1a1a"
        clip: true

        Image {
          anchors.fill: parent
          visible: root.trackArt.length > 0
          source: root.trackArt
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }

        IconImage {
          anchors.centerIn: parent
          visible: root.trackArt.length === 0
          implicitWidth: 16
          implicitHeight: 16
          source: Quickshell.iconPath("audio-x-generic-symbolic", "audio-x-generic-symbolic")
        }
      }

      ColumnLayout {
        spacing: 1
        Layout.maximumWidth: 160

        Text {
          Layout.fillWidth: true
          text: root.trackTitle
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
          visible: root.trackArtist.length > 0
          text: root.trackArtist
          color: "#888888"
          elide: Text.ElideRight
          font {
            family: "SF Pro Display"
            pixelSize: 11
          }
        }
      }
    }

    Item { Layout.fillWidth: true }

    // clock / date
    ColumnLayout {
      Layout.alignment: Qt.AlignVCenter
      spacing: 0

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(infoClock.date, "hh:mm")
        color: "#e8eaed"
        font {
          family: "SF Pro Display"
          pixelSize: 18
          weight: Font.Bold
        }

        SystemClock {
          id: infoClock
          precision: SystemClock.minutes
        }
      }

      Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDateTime(infoClock.date, "ddd, MMM d")
        color: "#888888"
        font {
          family: "SF Pro Display"
          pixelSize: 11
        }
      }
    }

    Item { Layout.fillWidth: true }

    // wifi + battery
    RowLayout {
      Layout.alignment: Qt.AlignVCenter
      spacing: 8

      IconImage {
        implicitWidth: 17
        implicitHeight: 17
        source: Quickshell.iconPath(
          root.wifiConnected ? "network-wireless-symbolic" : "network-wireless-offline-symbolic",
          "network-wireless-symbolic")
      }

      Rectangle {
        implicitWidth: batteryRow.implicitWidth + 16
        implicitHeight: 26
        radius: 13
        color: "#2a2a2a"

        RowLayout {
          id: batteryRow
          anchors.centerIn: parent
          spacing: 5

          IconImage {
            implicitWidth: 16
            implicitHeight: 16
            source: Quickshell.iconPath(
              UPower.displayDevice.iconName || (root.batteryCharging ? "battery-good-charging-symbolic" : "battery-good-symbolic"),
              "battery-good-symbolic")
          }

          Text {
            text: Math.round(root.batteryPct) + "%"
            color: "#e8eaed"
            font {
              family: "SF Pro Display"
              pixelSize: 12
              weight: Font.DemiBold
            }
          }
        }
      }
    }
  }
}
