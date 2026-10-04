import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

// The little popup the pill shows when a notification arrives.
// Content-only: Pill.qml decides when it's visible and how big the pill gets.
//   left click  -> open the full notification panel
//   right click -> dismiss this notification
Item {
    id: root

    property var notif: null          // the newest Notification (set by Pill.qml)
    signal clicked()
    signal dismissed()

    // ---- theme (same defaults as NotificationPanel) ----
    property color accent: "#7ecfff"
    property color danger: "#e05c5c"
    property color text:   "#e6edf3"
    property color dim:    "#8b949e"

    readonly property bool critical: notif?.urgency === NotificationUrgency.Critical

    implicitHeight: 56

    // quick fade whenever a newer notification replaces the one on screen
    onNotifChanged: swap.restart()

    Item {
        id: content
        anchors.fill: parent

        NumberAnimation { id: swap; target: content; property: "opacity"; from: 0.3; to: 1; duration: 200 }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 8
            spacing: 12

            // icon: notification image -> app icon -> first letter
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 38
                implicitHeight: 38
                radius: 12
                color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)

                Text {
                    anchors.centerIn: parent
                    visible: icon.status !== Image.Ready
                    text: (root.notif?.appName || "?").charAt(0).toUpperCase()
                    color: root.accent
                    font.pixelSize: 16
                    font.bold: true
                }
                Image {
                    id: icon
                    anchors.fill: parent
                    anchors.margins: 4
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    source: (root.notif?.image ?? "") !== "" ? root.notif.image
                          : (root.notif?.appIcon ?? "") !== "" ? Quickshell.iconPath(root.notif.appIcon, true)
                          : ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.notif?.summary ?? ""
                    color: root.text
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                Text {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: (root.notif?.body ?? "").replace(/\n/g, " ")
                    color: root.dim
                    font.pixelSize: 11
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }

            // critical notifications get a small red dot, nothing else
            Rectangle {
                visible: root.critical
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: root.danger
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => mouse.button === Qt.RightButton ? root.dismissed() : root.clicked()
    }
}
