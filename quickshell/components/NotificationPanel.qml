import QtQuick
import QtQuick.Layouts
import Quickshell

// Content-only panel. Pill.qml owns the NotificationServer and passes
// its trackedNotifications in, same pattern as the OSDs.
Item {
    id: root

    required property var notifications   // notifServer.trackedNotifications

    // ---- theme (swap these for your palette) ----
    property color accent: "#7ecfff"
    property color danger: "#e05c5c"
    property color text:   "#e6edf3"
    property color dim:    "#8b949e"
    property color card:   "#14ffffff"
    property color cardHover: "#1fffffff"

    readonly property int count: notifications.values.length
    property bool shown: false

    // Pill.qml hooks: Escape closes the panel, takeInitialFocus makes Escape work right away.
    signal closeRequested()
    function takeInitialFocus() { forceActiveFocus() }
    Keys.onEscapePressed: closeRequested()

    implicitWidth: 420
    implicitHeight: header.height + 12 + (count > 0 ? flick.height : 90)

    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }
    Component.onCompleted: shown = true

    function clearAll() {
        for (const n of [...notifications.values]) n.dismiss()
    }

    // ---------- header ----------
    RowLayout {
        id: header
        width: parent.width
        height: 32

        Text {
            text: "Notifications"
            color: root.text
            font.pixelSize: 16
            font.bold: true
        }

        Rectangle {
            visible: root.count > 0
            radius: 10
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.18)
            implicitWidth: badge.width + 14
            implicitHeight: 20
            Text {
                id: badge
                anchors.centerIn: parent
                text: root.count
                color: root.accent
                font.pixelSize: 12
                font.bold: true
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle {
            visible: root.count > 0
            radius: 12
            color: clearArea.containsMouse ? root.cardHover : root.card
            implicitWidth: clearText.width + 24
            implicitHeight: 28
            Behavior on color { ColorAnimation { duration: 150 } }
            Text {
                id: clearText
                anchors.centerIn: parent
                text: "Clear all"
                color: root.dim
                font.pixelSize: 12
            }
            MouseArea {
                id: clearArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearAll()
            }
        }
    }

    // ---------- empty state ----------
    Text {
        visible: root.count === 0
        anchors.top: header.bottom
        anchors.topMargin: 12
        width: parent.width
        height: 90
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: "You're all caught up"
        color: root.dim
        font.pixelSize: 13
    }

    // ---------- list ----------
    Flickable {
        id: flick
        visible: root.count > 0
        anchors.top: header.bottom
        anchors.topMargin: 12
        width: parent.width
        height: Math.min(contentHeight, 400)
        contentHeight: col.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: flick.width
            spacing: 8

            Repeater {
                model: root.notifications

                delegate: Rectangle {
                    id: item
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool critical: n.urgency === 2   // NotificationUrgency.Critical
                    property string time: Qt.formatTime(new Date(), "hh:mm")

                    width: col.width
                    height: body.implicitHeight + 28
                    radius: 16
                    color: hover.hovered ? root.cardHover : root.card
                    Behavior on color { ColorAnimation { duration: 150 } }

                    HoverHandler { id: hover }

                    // urgency strip
                    Rectangle {
                        visible: item.critical
                        width: 3
                        height: parent.height - 24
                        radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.danger
                    }

                    RowLayout {
                        id: body
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // icon (image -> app icon -> letter)
                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            implicitWidth: 38
                            implicitHeight: 38
                            radius: 12
                            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)

                            Text {
                                anchors.centerIn: parent
                                visible: icon.status !== Image.Ready
                                text: (item.n.appName || "?").charAt(0).toUpperCase()
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
                                source: item.n.image !== "" ? item.n.image
                                      : item.n.appIcon !== "" ? Quickshell.iconPath(item.n.appIcon, true)
                                      : ""
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: item.n.appName
                                    color: root.dim
                                    font.pixelSize: 11
                                }
                                Text {
                                    text: "·  " + item.time
                                    color: root.dim
                                    font.pixelSize: 11
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "✕"
                                    color: closeArea.containsMouse ? root.text : root.dim
                                    font.pixelSize: 12
                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: item.n.dismiss()
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: item.n.summary
                                color: root.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: item.n.body
                                color: root.dim
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                            }

                            // action buttons
                            Flow {
                                Layout.fillWidth: true
                                visible: item.n.actions.length > 0
                                spacing: 6

                                Repeater {
                                    model: item.n.actions
                                    delegate: Rectangle {
                                        required property var modelData
                                        radius: 10
                                        color: actArea.containsMouse
                                            ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
                                            : Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.15)
                                        implicitWidth: actText.width + 20
                                        implicitHeight: 26
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text {
                                            id: actText
                                            anchors.centerIn: parent
                                            text: modelData.text
                                            color: root.accent
                                            font.pixelSize: 12
                                        }
                                        MouseArea {
                                            id: actArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
