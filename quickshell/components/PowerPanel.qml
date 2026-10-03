import QtQuick

FocusScope {
    id: root

    // size helper: every number below is a design size, multiplied by Style.panelScale
    function px(n) { return Math.round(n * Style.panelScale) }

    property string pendingAction: ""
    readonly property var actions: [{
        "key": "suspend",
        "icon": "󰤄",
        "title": "Suspend"
    }, {
        "key": "lock",
        "icon": "󰌾",
        "title": "Lock"
    }, {
        "key": "logout",
        "icon": "󰍃",
        "title": "Log out"
    }, {
        "key": "reboot",
        "icon": "󰜉",
        "title": "Reboot"
    }, {
        "key": "shutdown",
        "icon": "󰐥",
        "title": "Power off"
    }]

    function activate(action) {
        const needsConfirmation = action === "reboot" || action === "shutdown";
        if (needsConfirmation && pendingAction !== action) {
            pendingAction = action;
            confirmReset.restart();
            return ;
        }
        Backend.power(action);
        ShellState.close();
    }

    function focusAction(index) {
        const count = actions.length;
        const next = (index + count) % count;
        const item = actionRepeater.itemAt(next);
        if (item)
            item.forceActiveFocus(Qt.TabFocusReason);
    }

    function takeInitialFocus() {
        focusAction(0);
    }

    implicitWidth: root.px(352)
    implicitHeight: content.implicitHeight
    Keys.onEscapePressed: ShellState.close()

    Timer {
        id: confirmReset

        interval: 3000
        onTriggered: root.pendingAction = ""
    }

    Column {
        id: content

        width: parent.width
        spacing: root.px(8)
        Row {
            width: parent.width
            height: root.px(56)
            spacing: root.px(8)
            Repeater {
                id: actionRepeater

                model: root.actions

                delegate: FocusScope {
                    id: actionButton

                    required property int index
                    required property var modelData
                    readonly property bool highlighted: activeFocus || pointer.containsMouse

                    width: root.px(64)
                    height: parent.height
                    activeFocusOnTab: true
                    Keys.onReturnPressed: root.activate(modelData.key)
                    Keys.onEnterPressed: root.activate(modelData.key)
                    Keys.onSpacePressed: root.activate(modelData.key)
                    Keys.onLeftPressed: root.focusAction(index - 1)
                    Keys.onUpPressed: root.focusAction(index - 1)
                    Keys.onRightPressed: root.focusAction(index + 1)
                    Keys.onDownPressed: root.focusAction(index + 1)
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.title

                    Rectangle {
                        anchors.fill: parent
                        radius: Style.radius
                        color: root.pendingAction === modelData.key ? Style.yellow : (actionButton.highlighted ? Style.primary : Style.bg1)
                        border.width: parent.activeFocus ? 2 : 0
                        border.color: Style.primary

                        Behavior on color {
                            ColorAnimation {
                                duration: Style.animationFast
                            }

                        }

                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: root.px(4)
                        ShellText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.pendingAction === modelData.key ? "?" : modelData.icon
                            color: root.pendingAction === modelData.key || actionButton.highlighted ? Style.bgDim : Style.muted
                            font.pixelSize: root.px(16)
                            font.weight: Font.Bold
                        }

                        ShellText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.pendingAction === modelData.key ? "Confirm" : modelData.title
                            color: root.pendingAction === modelData.key || actionButton.highlighted ? Style.bgDim : Style.muted
                            font.pixelSize: root.px(9)
                            font.weight: Font.Black
                        }

                    }

                    MouseArea {
                        id: pointer

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(modelData.key)
                    }

                }

            }

        }

    }

}
