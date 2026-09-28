import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Notification history — sourced into ControlCenter.qml's Loader.
//
// NOTE: this is a shell/placeholder. Wiring real notification history
// depends on your notification daemon (you're on swaync per your
// other configs) — swaync doesn't expose a stable QML-friendly source
// here, so hook this up to `swaync-client -l` (JSON output) in the
// Process below once you confirm its output format on your system.
Item {
  id: root
  implicitWidth: 460
  implicitHeight: 400

  signal back()
  signal closeRequested()

  property var notifications: []

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
        text: "Notifications"
        color: "#e8eaed"
        Layout.fillWidth: true
        font {
          family: "SF Pro Display"
          pixelSize: 15
          weight: Font.DemiBold
        }
      }

      Text {
        visible: root.notifications.length > 0
        text: "Clear all"
        color: "#7ecfff"
        font.pixelSize: 12
        MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.notifications = [] }
      }
    }

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 6
      model: root.notifications

      Text {
        anchors.centerIn: parent
        visible: root.notifications.length === 0
        text: "No notifications"
        color: "#666666"
        font {
          family: "SF Pro Display"
          pixelSize: 13
        }
      }

      delegate: Rectangle {
        required property var modelData
        width: ListView.view.width
        implicitHeight: 56
        radius: 10
        color: "#1a1a1a"

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 1

          Text {
            text: modelData.summary || ""
            color: "#e8eaed"
            elide: Text.ElideRight
            Layout.fillWidth: true
            font {
              family: "SF Pro Display"
              pixelSize: 13
              weight: Font.DemiBold
            }
          }

          Text {
            text: modelData.body || ""
            color: "#999999"
            elide: Text.ElideRight
            Layout.fillWidth: true
            font {
              family: "SF Pro Display"
              pixelSize: 11
            }
          }
        }
      }
    }
  }

  Keys.onEscapePressed: root.back()
}
