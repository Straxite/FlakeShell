import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

// Wallpaper filmstrip that lives INSIDE the pill (loaded by Pill.qml, same way as Launcher).
// Focused thumb is big and bright, neighbours shrink/dim/desaturate as they slide away.
// Left/Right (or h/l) or the scroll wheel move, Enter or click on the focused thumb applies,
// click a neighbour to glide to it, Escape closes.
Item {
    id: root
    opacity: pill.isOpen ? 1 : 0
    Behavior on opacity {
        NumberAnimation { duration: 800; easing.type: Easing.OutCubic }
    }

    // ───── CONFIG: the two things you might want to change ─────
    // Fallback folder. The theme menu overrides it by writing a path into wallDirFile.
    property string wallDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string wallDirFile: Quickshell.env("HOME") + "/.cache/quickshell-wallpaper-dir"
    // Wallpaper application is handled step-by-step below so failures do not
    // silently prevent Matugen or the notification from running.
    function applyCommand(path) {
        return ["awww", "img", path, "--transition-type", "center", "--transition-fps", "60"]
    }

    // Persistent wallpaper selection.
    // The full path is stored so the selection survives sorting/order changes.
    readonly property string wallpaperStateFile: Quickshell.env("HOME") + "/.cache/quickshell-wallpaper-selected"
    property string savedWallpaper: ""

    signal closeRequested()   // Pill.qml listens to this and closes the strip

    implicitHeight: 100       // Pill adds its own padding on top of this

    // ───── state ─────
    property var allFiles: []        // all wallpapers, newest first
    property var files: []           // currently visible/search-filtered wallpapers
    property int focusIndex: 0
    property real pos: 0
    property string searchQuery: ""
    readonly property int count: files.length

    function updateSearch() {
        const q = root.searchQuery.trim().toLowerCase()
        root.files = q === "" ? root.allFiles : root.allFiles.filter(path => path.split("/").pop().toLowerCase().includes(q))
        root.focusIndex = 0
        root.pos = 0
        root.restoreSelection()
    }

    function searchKey(event) {
        if (event.key === Qt.Key_Backspace) { root.searchQuery = root.searchQuery.slice(0, -1); root.updateSearch(); return true }
        if (event.key === Qt.Key_Space) { root.searchQuery += " "; root.updateSearch(); return true }
        if (event.text && event.text.length > 0 && !event.modifiers && /^[A-Za-z0-9._-]$/.test(event.text)) {
            root.searchQuery += event.text
            root.updateSearch()
            return true
        }
        return false
    }

    // ───── 1. find the wallpapers ─────
    Process {
        id: savedWallpaperReader
        running: true
        command: ["sh", "-c", 'cat -- "$1" 2>/dev/null || true', "sh", root.wallpaperStateFile]
        stdout: StdioCollector {
            onStreamFinished: {
                root.savedWallpaper = text.trim()
                root.restoreSelection()
            }
        }
    }

    function restoreSelection() {
        if (root.count === 0 || root.savedWallpaper === "") return
        const savedIndex = root.files.indexOf(root.savedWallpaper)
        if (savedIndex >= 0) {
            root.focusIndex = savedIndex
            root.pos = savedIndex
        }
    }

    // read the folder chosen by the theme menu (if any), THEN list it
    Process {
        id: dirReader
        running: true
        command: ["sh", "-c", 'cat -- "$1" 2>/dev/null || true', "sh", root.wallDirFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const d = text.trim()
                if (d !== "") root.wallDir = d
                lister.running = true
            }
        }
    }

    Process {
        id: lister
        running: false
        // find image files in the folder, newest first, one path per line
        command: ["sh", "-c",
            "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) -printf '%T@\\t%p\\n' | sort -rn | cut -f2-",
            "sh", root.wallDir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.allFiles = text.split("\n").filter(l => l.length > 0)
                root.updateSearch()
            }
        }
    }

    // ───── 2. applying ─────
    // Each step is a separate Process. This avoids shell quoting/PATH issues and
    // guarantees Matugen + notify-send only run after awww succeeds.
    Process {
        id: applyProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                saveWallpaper.running = true
            } else {
                console.warn("awww failed with exit code:", exitCode)
            }
        }
    }

    Process {
        id: saveWallpaper
        command: ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"", "sh", root.wallpaperStateFile, root.selectedWallpaper]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                matugenProc.running = true
            } else {
                console.warn("Failed to save wallpaper selection, exit code:", exitCode)
            }
        }
    }

    Process {
        id: matugenProc
        command: ["matugen", "image", root.selectedWallpaper, "--source-color-index", "0", "--type", "scheme-tonal-spot"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                notifyProc.running = true
            } else {
                console.warn("Matugen failed with exit code:", exitCode)
            }
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "Wallpaper Switcher", "Wallpaper Successfully Changed"]
    }

    property string selectedWallpaper: ""

    function apply(i) {
        if (i < 0 || i >= count) return

        root.selectedWallpaper = files[i]

        // Run awww first. The next processes are chained from onExited.
        applyProc.command = applyCommand(root.selectedWallpaper)
        applyProc.running = true
    }

    function move(delta) {
        if (count === 0) return
        focusIndex = Math.max(0, Math.min(count - 1, focusIndex + delta))
    }

    // file path -> safe file:// url (handles spaces, # and ? in names)
    function urlFor(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    // ───── 3. smooth scrolling ─────
    // Tiles are drawn from this single `pos` value, which exponentially chases focusIndex.
    // That keeps fast key repeat and wheel bursts smooth instead of stacking animations.
    FrameAnimation {
        running: root.pos !== root.focusIndex
        onTriggered: {
            const k = 1 - Math.exp(-frameTime / 0.14)
            const next = root.pos + (root.focusIndex - root.pos) * k
            root.pos = Math.abs(next - root.focusIndex) < 0.005 ? root.focusIndex : next
        }
    }

    // ───── 4. the "depth" look ─────
    // Index 0 = focused tile, 1 = one step away, ... Values in between are interpolated,
    // so tiles smoothly shrink/dim as they slide away from the center.
    readonly property var slotW:      [160, 104, 84, 68, 56]    // tile width
    readonly property var slotH:      [90, 58, 47, 38, 31]      // tile height
    readonly property var slotCX:     [0, 118, 200, 262, 308]   // distance from center
    readonly property var slotBright: [1, 0.56, 0.42, 0.30, 0.22]
    readonly property var slotSat:    [1, 0.65, 0.55, 0.45, 0.40]

    function slotLerp(arr, ao) {
        if (ao >= 4) return arr[4]
        const i = Math.floor(ao)
        return arr[i] + (arr[i + 1] - arr[i]) * (ao - i)
    }

    function offsetX(off) {
        const ao = Math.abs(off)
        const cx = ao <= 4 ? slotLerp(slotCX, ao) : slotCX[4] + (ao - 4) * 60
        return off < 0 ? -cx : cx
    }

    // ───── 5. tiles ─────
    // Only 11 tiles ever exist, no matter how many wallpapers you have. Tile `index`
    // always shows the wallpaper whose number % 11 == index inside the window around
    // the camera, so scrolling by one only swaps the tile at the far edge.
    readonly property int poolSize: 11
    readonly property int winLo: Math.round(pos) - 5

    // ───── 5.5. HUD ─────
    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 16
        anchors.topMargin: 4
        text: "Wallpaper  •  " + root.wallDir.split("/").pop()
        color: "#eeffffff"
        font.pixelSize: 13
        font.weight: Font.Medium
        z: 100
    }

    Text {
        id: countText
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 16
        anchors.topMargin: 8
        text: root.searchQuery.length > 0 ? root.searchQuery + "  •  " + (root.count > 0 ? root.focusIndex + 1 : 0) + "/" + root.count : (root.count > 0 ? root.focusIndex + 1 : 0) + "/" + root.count
        color: "#bbffffff"
        font.pixelSize: 11
        horizontalAlignment: Text.AlignRight
        z: 100
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: 7
        text: "← / →   •   Return ↵"
        color: "#88ffffff"
        font.pixelSize: 10
        z: 100
    }

    Rectangle {
        visible: root.searchQuery.length > 0
        anchors.right: countText.left
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.rightMargin: 10
        width: Math.min(150, root.width * 0.25)
        height: 24
        radius: 7
        color: "#18ffffff"
        border.width: 1
        border.color: "#30ffffff"
        z: 101
        Text {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            verticalAlignment: Text.AlignVCenter
            text: root.searchQuery
            color: "#eeffffff"
            font.pixelSize: 11
            elide: Text.ElideLeft
        }
    }

    Repeater {
        model: root.poolSize

        delegate: Item {
            id: tile
            required property int index

            readonly property int gridIndex: root.winLo + (((index - root.winLo) % root.poolSize) + root.poolSize) % root.poolSize
            readonly property bool dead: gridIndex < 0 || gridIndex >= root.count
            readonly property real off: gridIndex - root.pos
            readonly property real ao: Math.abs(off)
            readonly property bool focused: gridIndex === root.focusIndex
            readonly property real bright: root.slotLerp(root.slotBright, ao)
            readonly property real sat: root.slotLerp(root.slotSat, ao)

            // fade out near the left/right edge so the strip ends soften instead of hard-cutting
            readonly property real edgeFade: Math.max(0, Math.min(1, Math.min(x, root.width - (x + width)) / 50))

            width: root.slotLerp(root.slotW, ao)
            height: root.slotLerp(root.slotH, ao)
            x: root.width / 2 + root.offsetX(off) - width / 2
            y: (root.height - height) / 2
            z: 10 - ao
            visible: !dead && ao <= 5
            opacity: edgeFade * (ao <= 4 ? 1 : Math.max(0, 5 - ao))

            ClippingRectangle {
                anchors.fill: parent
                radius: 8 + 2 * Math.max(0, 1 - tile.ao)
                color: "#1a1a1a"

                // desaturate tiles the further they are from the center
                layer.enabled: tile.visible
                layer.effect: MultiEffect { saturation: tile.sat - 1 }

                Image {
                    anchors.fill: parent
                    // only load while visible. sourceSize keeps decoded thumbs small.
                    source: tile.visible ? root.urlFor(root.files[tile.gridIndex]) : ""
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 360
                }

                // darken tiles the further they are from the center
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 1 - tile.bright
                }
            }

            // thin outline, brighter on the focused tile
            Rectangle {
                anchors.fill: parent
                radius: 8 + 2 * Math.max(0, 1 - tile.ao)
                color: "transparent"
                border.width: 1
                border.color: tile.focused ? "#aaffffff" : "#22ffffff"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // click the focused one = apply, click a neighbour = glide to it
                onClicked: tile.focused ? root.apply(tile.gridIndex) : root.focusIndex = tile.gridIndex
            }
        }
    }

    // shown when the folder is empty or missing
    Text {
        anchors.centerIn: parent
        visible: root.count === 0 && !lister.running
        text: "No wallpapers in " + root.wallDir
        color: "#88ffffff"
        font.pixelSize: 12
    }

    // scroll wheel moves the strip (doesn't block clicks)
    MouseArea {
        anchors.fill: parent
        z: 20
        acceptedButtons: Qt.NoButton
        property real acc: 0
        onWheel: event => {
            acc += event.angleDelta.y / 120
            const notches = Math.trunc(acc)
            if (notches !== 0) {
                root.move(-notches)
                acc -= notches
            }
            event.accepted = true
        }
    }

    // keyboard
    focus: true
    Component.onCompleted: forceActiveFocus()
    Keys.onPressed: event => {
        let handled = true
        if (event.key === Qt.Key_Escape) {
            if (root.searchQuery.length > 0) { root.searchQuery = ""; root.updateSearch() }
            else closeRequested()
        }
        else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) move(-1)
        else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) move(1)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) apply(focusIndex)
        else handled = root.searchKey(event)
        event.accepted = handled
    }
}
