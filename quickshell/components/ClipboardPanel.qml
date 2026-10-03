import QtQuick
import Quickshell

// Clipboard history in the Launcher's layout: pill-shaped search bar on top, rows below
// (46px rows, 12px radius, #313036 highlight, white accent bar, up to 6 rows visible).
// Space = show/hide the full content preview, Enter = copy it back, Esc = close.
FocusScope {
    id: root

    // same numbers as Launcher.qml
    readonly property int rowHeight: 46
    readonly property int rowSpacing: 4
    readonly property int maxVisibleRows: 6
    readonly property int searchBarHeight: 60
    readonly property int sectionSpacing: 10

    readonly property int itemCount: filteredItems.values.length
    readonly property int visibleRows: Math.max(1, Math.min(itemCount, maxVisibleRows))
    readonly property real listHeight: itemCount === 0 ? rowHeight : visibleRows * rowHeight + (visibleRows - 1) * rowSpacing
    readonly property real previewHeight: previewVisible ? 156 : 0

    property int selectedIndex: 0
    property bool previewVisible: false
    property bool previewTransitionActive: false
    property string previewItemId: ""
    onSelectedIndexChanged: Qt.callLater(root.syncPreviewToSelection)

    function takeInitialFocus() {
        selectedIndex = 0;
        previewVisible = false;
        previewItemId = "";
        Backend.refreshClipboard();
        searchInput.forceActiveFocus(Qt.TabFocusReason);
    }

    Connections {
        function onPanelChanged() {
            if (ShellState.panel !== "clipboard") {
                searchInput.clear();
                root.selectedIndex = 0;
                root.previewVisible = false;
                root.previewItemId = "";
            }
        }

        target: ShellState
    }

    function selectedItem() {
        if (filteredItems.values.length === 0)
            return null;

        return filteredItems.values[Math.min(selectedIndex, filteredItems.values.length - 1)];
    }

    function moveSelection(offset) {
        const count = filteredItems.values.length;
        if (count === 0)
            return;

        selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + offset));
        clipboardList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function togglePreview() {
        const item = selectedItem();
        if (!item)
            return ;

        previewTransitionActive = true;
        previewTransitionTimer.restart();
        if (previewVisible && previewItemId === item.id) {
            previewVisible = false;
            return ;
        }
        previewVisible = true;
        showPreview(item);
    }

    function showPreview(item) {
        previewItemId = item.id;
        Backend.loadClipboardContents(item.id, item.preview, item.imageSource);
    }

    function syncPreviewToSelection() {
        if (!previewVisible)
            return ;

        const item = selectedItem();
        if (!item) {
            previewVisible = false;
            previewItemId = "";
            return ;
        }
        if (item.id !== previewItemId)
            showPreview(item);
    }

    function activateSelection() {
        const item = selectedItem();
        if (!item)
            return ;

        Backend.pasteClipboard(item.id);
        ShellState.close();
    }

    // one-line label for a row ("Image · 1024x768 png" for pictures)
    function rowLabel(item) {
        const text = item.imageSource
            ? item.preview.replace(/^\[\[ binary data /, "Image · ").replace(/ \]\]$/, "")
            : item.preview;
        return text.replace(/\s+/g, " ").trim();
    }

    implicitWidth: 480
    implicitHeight: searchBarHeight + sectionSpacing + listHeight + (previewVisible ? sectionSpacing + previewHeight : 0)
    Keys.onEscapePressed: ShellState.close()

    Timer {
        id: previewTransitionTimer

        interval: Style.animationFast
        onTriggered: root.previewTransitionActive = false
    }

    Column {
        id: content

        width: parent.width
        spacing: root.sectionSpacing

        // ── search bar (Launcher style) ──
        Rectangle {
            width: parent.width
            height: root.searchBarHeight
            radius: 99
            color: "#000000"

            Text {
                text: "\uf002"
                color: "#e8eaed"
                font.family: Style.fontFamily
                font.pixelSize: 18
                font.weight: 600
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenterOffset: -220
                anchors.verticalCenterOffset: -5
            }

            // the thin line under the text, like the launcher's
            Rectangle {
                height: 0.6
                radius: 16
                width: 450
                color: "#ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 20
            }

            TextInput {
                id: searchInput

                anchors.fill: parent
                anchors.leftMargin: 40
                anchors.rightMargin: 14
                anchors.bottomMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: "#e8eaed"
                font.family: "SF Pro Display"
                font.pixelSize: 15
                clip: true
                selectByMouse: true
                activeFocusOnTab: true
                onTextChanged: {
                    root.selectedIndex = 0;
                    Qt.callLater(root.syncPreviewToSelection);
                }
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onReturnPressed: root.activateSelection()
                Keys.onEnterPressed: root.activateSelection()
                Keys.onSpacePressed: root.togglePreview()
                Keys.onEscapePressed: ShellState.close()
            }
        }

        // ── history list ──
        ListView {
            id: clipboardList

            width: parent.width
            height: root.listHeight
            spacing: root.rowSpacing
            clip: true

            Text {
                anchors.centerIn: parent
                visible: root.itemCount === 0
                text: searchInput.text ? "Nothing Found" : "Clipboard history is empty"
                color: "#666666"
                font.family: "SF Pro Display"
                font.pixelSize: 14
            }

            model: ScriptModel {
                id: filteredItems

                objectProp: "id"
                values: Backend.clipboardItems.filter((item) => {
                    return !searchInput.text || item.preview.toLowerCase().includes(searchInput.text.toLowerCase());
                })
            }

            delegate: Rectangle {
                id: entry

                required property var modelData
                required property int index
                readonly property bool selected: index === root.selectedIndex

                width: clipboardList.width
                height: root.rowHeight
                radius: 12
                color: selected ? "#313036" : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 100 }
                }

                // accent bar on the left of the selected row
                Rectangle {
                    width: entry.selected ? 4 : 0
                    height: entry.selected ? 20 : 0
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 16
                    color: "#ffffff"

                    Behavior on width {
                        NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
                    }

                    Behavior on height {
                        NumberAnimation { duration: 100 }
                    }
                }

                Item {
                    id: iconSlot

                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24

                    // text entry: a glyph
                    Text {
                        anchors.centerIn: parent
                        visible: !entry.modelData.imageSource
                        text: "\uf0ea"
                        color: "#7d8087"
                        font.family: Style.fontFamily
                        font.pixelSize: 16
                    }

                    // image entry: its thumbnail
                    Image {
                        anchors.fill: parent
                        visible: !!entry.modelData.imageSource
                        source: entry.modelData.imageSource || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 48
                        sourceSize.height: 48
                    }
                }

                Text {
                    anchors.left: iconSlot.right
                    anchors.leftMargin: 10
                    anchors.right: typeLabel.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.rowLabel(entry.modelData)
                    color: "#e8eaed"
                    elide: Text.ElideRight
                    font.family: "SF Pro Display"
                    font.pixelSize: 14
                }

                Text {
                    id: typeLabel

                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: entry.modelData.imageSource ? "Image" : "Text"
                    color: "#7d8087"
                    horizontalAlignment: Text.AlignRight
                    font.family: "SF Pro Display"
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = entry.index
                    onClicked: root.activateSelection()
                }
            }
        }

        // ── full-content preview (Space) ──
        Rectangle {
            width: parent.width
            height: root.previewHeight
            radius: 12
            color: "#000000"
            border.width: 1
            border.color: "#313036"
            clip: true
            visible: height > 0

            Text {
                id: previewLabel

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.leftMargin: 12
                anchors.topMargin: 10
                text: "Full content"
                color: "#7d8087"
                font.family: "SF Pro Display"
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Flickable {
                id: previewViewport

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: previewLabel.bottom
                anchors.bottom: parent.bottom
                anchors.margins: 12
                anchors.topMargin: 8
                contentWidth: width
                contentHeight: Math.max(height, previewText.implicitHeight)
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Text {
                    id: previewText

                    width: previewViewport.width
                    visible: !Backend.clipboardImageSource
                    text: Backend.clipboardContentsLoading ? "Loading…" : Backend.clipboardContents
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Backend.clipboardContentsLoading ? "#7d8087" : "#e8eaed"
                    font.family: "SF Pro Display"
                    font.pixelSize: 12
                }

                Image {
                    anchors.fill: parent
                    visible: !!Backend.clipboardImageSource
                    source: Backend.clipboardImageSource
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                }
            }
        }
    }
}
