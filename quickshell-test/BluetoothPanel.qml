import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Bluetooth device list — sourced into ControlCenter.qml's Loader when
// the Bluetooth card's chevron is clicked.
Item {
  id: root
  implicitWidth: 460
  implicitHeight: 400

  signal back()
  signal closeRequested()

  property var devices: []
  property bool scanning: false

  function refresh() {
    root.scanning = true
    listProcess.running = true
  }

  // For each paired device, prints "MAC|Name|yes-or-no" (connected).
  // bluetoothctl info per device is slow-ish with lots of devices, but
  // fine for a normal handful of paired peripherals.
  Process {
    id: listProcess
    command: ["bash", "-lc",
      "bluetoothctl devices 2>/dev/null | while read -r _ mac name; do " +
      "  c=$(bluetoothctl info \"$mac\" 2>/dev/null | grep -q 'Connected: yes' && echo yes || echo no); " +
      "  echo \"$mac|$name|$c\"; " +
      "done"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n").filter(l => l.length > 0)
        var result = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split("|")
          if (parts.length < 3) continue
          result.push({
            mac: parts[0],
            name: parts[1],
            connected: parts[2] === "yes"
          })
        }
        result.sort(function(a, b) { return (b.connected ? 1 : 0) - (a.connected ? 1 : 0) })
        root.devices = result
        root.scanning = false
      }
    }
  }

  Process {
    id: connectionProcess
    property string mac: ""
    property bool connect: true
    command: ["bash", "-lc", "bluetoothctl $1 \"$2\"", "bluetooth-panel", connect ? "connect" : "disconnect", mac]
    onRunningChanged: if (!running) root.refresh()
  }

  function toggleConnection(device) {
    connectionProcess.mac = device.mac
    connectionProcess.connect = !device.connected
    connectionProcess.running = true
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
        text: "Bluetooth Devices"
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
        text: "loading…"
        color: "#666666"
        font.pixelSize: 11
      }
    }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 4
      model: root.devices

      Text {
        anchors.centerIn: parent
        visible: !root.scanning && root.devices.length === 0
        text: "No paired devices"
        color: "#666666"
        font.pixelSize: 13
      }

      delegate: Rectangle {
        id: btDelegate
        required property var modelData

        width: ListView.view.width
        implicitHeight: 48
        radius: 10
        color: modelData.connected ? "#7ecfff22" : "#1a1a1a"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 12
          anchors.rightMargin: 12
          spacing: 10

          IconImage {
            implicitWidth: 18
            implicitHeight: 18
            source: Quickshell.iconPath("bluetooth-active-symbolic", "bluetooth-active-symbolic")
          }

          Text {
            text: btDelegate.modelData.name
            color: "#e8eaed"
            elide: Text.ElideRight
            Layout.fillWidth: true
            font {
              family: "SF Pro Display"
              pixelSize: 13
            }
          }

          Text {
            text: btDelegate.modelData.connected ? "Connected" : "Connect"
            color: btDelegate.modelData.connected ? "#7ecfff" : "#888888"
            font.pixelSize: 11
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: root.toggleConnection(btDelegate.modelData)
        }
      }
    }
  }

  Keys.onEscapePressed: root.back()

  Component.onCompleted: root.refresh()
}
