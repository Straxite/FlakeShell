import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Wi-Fi network list — sourced into ControlCenter.qml's Loader when
// the Wi-Fi card's chevron is clicked.
Item {
  id: root
  implicitWidth: 460
  implicitHeight: 400

  signal back()
  signal closeRequested()

  property var networks: []
  property bool scanning: false

  function refresh() {
    root.scanning = true
    scanProcess.running = true
  }

  Process {
    id: scanProcess
    command: ["bash", "-lc",
      "nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list --rescan yes 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n").filter(l => l.length > 0)
        var seen = {}
        var result = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(":")
          var ssid = parts[0]
          if (!ssid || seen[ssid]) continue
          seen[ssid] = true
          result.push({
            ssid: ssid,
            signal: parseInt(parts[1]) || 0,
            security: parts[2] || "",
            active: parts[3] === "yes"
          })
        }
        result.sort(function(a, b) { return b.signal - a.signal })
        root.networks = result
        root.scanning = false
      }
    }
  }

  Process {
    id: connectProcess
    property string ssid: ""
    command: ["bash", "-lc", "nmcli device wifi connect \"$1\"", "network-panel", ssid]
    onRunningChanged: if (!running) root.refresh()
  }

  function connectTo(ssid) {
    connectProcess.ssid = ssid
    connectProcess.running = true
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 10

    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      Text {
        text: "\u2039"
        color: "#e8eaed"
        font.pixelSize: 20
        MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: root.back() }
      }

      Text {
        text: "Wi-Fi Networks"
        color: "#e8eaed"
        Layout.fillWidth: true
        font {
          family: "SF Pro Display"
          pixelSize: 15
          weight: Font.DemiBold
        }
      }

      Text {
        visible: root.scanning
        text: "scanning…"
        color: "#666666"
        font.pixelSize: 11
      }
    }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 4
      model: root.networks

      Text {
        anchors.centerIn: parent
        visible: !root.scanning && root.networks.length === 0
        text: "No networks found"
        color: "#666666"
        font.pixelSize: 13
      }

      delegate: Rectangle {
        id: netDelegate
        required property var modelData

        width: ListView.view.width
        implicitHeight: 48
        radius: 10
        color: modelData.active ? "#7ecfff22" : "#1a1a1a"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 10

          IconImage {
            implicitWidth: 18
            implicitHeight: 18
            source: Quickshell.iconPath("network-wireless-symbolic", "network-wireless-symbolic")
          }

          Text {
            text: netDelegate.modelData.ssid
            color: "#e8eaed"
            elide: Text.ElideRight
            Layout.fillWidth: true
            font {
              family: "SF Pro Display"
              pixelSize: 13
            }
          }

          Text {
            visible: netDelegate.modelData.security.length > 0 && netDelegate.modelData.security !== "--"
            text: "\uD83D\uDD12"
            color: "#888888"
            font.pixelSize: 11
          }

          Text {
            visible: netDelegate.modelData.active
            text: "Connected"
            color: "#7ecfff"
            font.pixelSize: 11
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.connectTo(netDelegate.modelData.ssid)
        }
      }
    }
  }

  Keys.onEscapePressed: root.back()

  Component.onCompleted: root.refresh()
}
