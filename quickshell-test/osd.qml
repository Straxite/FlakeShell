//
// Flow OS — Right-side hover panel (audio + brightness)
// Caelestia-style notch panel. Drop this in ~/.config/quickshell/shell.qml
//
// Deps: quickshell (with Pipewire service compiled in), brightnessctl
//
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "./Theme" as Theme

ShellRoot {
    id: root

    // ---- theme (matugen-driven — see Theme/Colors.qml.template) ----
    readonly property color accent: Theme.Colors.accent
    readonly property color bg: Theme.Colors.bg
    readonly property color track: Theme.Colors.track

    // ---- geometry ----
    readonly property int cardWidth: 176
    readonly property int cardHeight: 220
    readonly property int cardRadius: 22

    // ---- state ----
    property bool hovered: false
    property bool panelHovered: false
    property bool peeking: false   // true briefly after a volume/brightness change

    property bool open: hovered || panelHovered || peeking

    Timer {
        id: peekTimer
        interval: 1400
        onTriggered: root.peeking = false
    }
    function peek() {
        peeking = true;
        peekTimer.restart();
    }

    // ================= Pipewire (volume) =================
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    property var sink: Pipewire.defaultAudioSink
    // hard-clamped to 0..1 — some backends allow >100% volume, we never show/allow that
    readonly property real volume: sink && sink.audio ? Math.max(0, Math.min(1, sink.audio.volume)) : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

    onVolumeChanged: peek()

    function setVolume(v) {
        if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    // ================= Brightness (brightnessctl) =================
    // Use brightnessctl's own computed percent field instead of doing
    // current/max math ourselves — avoids the "20000%" bug entirely, since
    // that came from raw absolute units when the max-brightness parse
    // failed on some backlight drivers.
    property real brightness: 0.6

    onBrightnessChanged: peek()

    Process {
        id: getBrightness
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                // format: device,class,current,percent%,max
                const parts = data.trim().split(",");
                if (parts.length >= 4) {
                    const pct = parseInt(parts[3]); // parseInt stops at the trailing '%'
                    if (!isNaN(pct)) root.brightness = Math.max(0, Math.min(1, pct / 100));
                }
            }
        }
    }
    Process {
        id: setBrightnessProc
        command: ["brightnessctl", "set", "100%"]
    }
    function setBrightness(v) {
        root.brightness = Math.max(0, Math.min(1, v));
        const pct = Math.round(root.brightness * 100);
        setBrightnessProc.command = ["brightnessctl", "set", pct + "%"];
        setBrightnessProc.running = true;
    }

    // poll for external changes (keybinds, other tools) so panel pops up
    // and stays in sync even when brightness changes outside this file
    Timer {
        interval: 400; running: true; repeat: true
        onTriggered: getBrightness.running = true
    }

    // ================= Panel window =================
    // Fixed-size window, always docked to the edge. We NEVER resize the
    // window itself (that's what caused the snapping/jank) — only the
    // card *inside* it slides via an anchor margin, which animates smoothly.
    PanelWindow {
        id: panel
        screen: Quickshell.screens[0]

        anchors { top: true; bottom: true; right: true }
        implicitWidth: root.cardWidth + 12

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "flowos-sidepanel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        color: "transparent"

        // whole window is always a live hover surface
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.hovered = true
            onExited: root.hovered = false
        }

        // notch: card slides in from the right; when "open" it overhangs the
        // screen edge by cardRadius so the window clips its right corners,
        // leaving only the left corners rounded — flush apple-notch look.
        Item {
            id: card
            width: root.cardWidth
            height: root.cardHeight
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.open ? -root.cardRadius : -width

            Behavior on anchors.rightMargin {
                NumberAnimation { duration: 260; easing.type: Easing.OutExpo }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.panelHovered = true
                onExited: root.panelHovered = false

                Rectangle {
                    anchors.fill: parent
                    radius: root.cardRadius
                    color: root.bg
                    border.color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.35)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        anchors.rightMargin: 14 + root.cardRadius // keep content clear of the clipped notch edge
                        spacing: 18

                        SliderColumn {
                            icon: root.muted ? "\uf6a9" : "\uf028"
                            value: root.volume
                            accent: root.accent
                            track: root.track
                            onMoved: v => root.setVolume(v)
                        }

                        SliderColumn {
                            icon: "\uf185"
                            value: root.brightness
                            accent: root.accent
                            track: root.track
                            onMoved: v => root.setBrightness(v)
                        }
                    }
                }
            }
        }
    }

    // ================= icon + vertical slider + percentage, as one column =================
    component SliderColumn: ColumnLayout {
        property string icon
        property real value
        property color accent
        property color track
        signal moved(real v)

        Layout.fillHeight: true
        spacing: 8

        Text {
            text: parent.icon
            color: parent.accent
            font.pixelSize: 18
            Layout.alignment: Qt.AlignHCenter
        }

        VerticalSlider {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            value: parent.value
            accent: parent.accent
            track: parent.track
            onMoved: v => parent.moved(v)
        }

        Text {
            text: Math.round(parent.value * 100) + "%"
            color: "#cccccc"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignHCenter
        }
    }

    // ================= reusable vertical slider =================
    component VerticalSlider: Item {
        id: sliderRoot
        property real value: 0.5
        property color accent: "#7ecfff"
        property color track: "#2a2a2a"
        signal moved(real v)

        implicitWidth: 10
        implicitHeight: 130

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: sliderRoot.track
        }
        Rectangle {
            width: parent.width
            height: parent.height * sliderRoot.value
            anchors.bottom: parent.bottom
            radius: width / 2
            color: sliderRoot.accent

            Behavior on height {
                enabled: !dragArea.pressed
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            anchors.margins: -6
            onPressed: mouse => updateFromY(mouse.y)
            onPositionChanged: mouse => { if (pressed) updateFromY(mouse.y); }

            function updateFromY(y) {
                const h = sliderRoot.height;
                const clamped = Math.max(0, Math.min(h, y));
                const v = 1 - (clamped / h);
                sliderRoot.value = v;
                sliderRoot.moved(v);
            }
        }
    }
}
