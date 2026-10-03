// shell.qml
import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root
            required property var modelData
            screen: modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            mask: Region {}

            property int radius: 15
            property color maskColor: "black" // match bezel/bg color

            Repeater {
                model: [
                    { x: 0, y: 0 },                                       // top-left
                    { x: root.width - root.radius, y: 0 },                // top-right
                    { x: 0, y: root.height - root.radius },               // bottom-left
                    { x: root.width - root.radius, y: root.height - root.radius } // bottom-right
                ]

                Canvas {
                    id: corner
                    required property var modelData
                    required property int index

                    x: modelData.x
                    y: modelData.y
                    width: root.radius
                    height: root.radius

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        // fill the whole quadrant black first
                        ctx.fillStyle = root.maskColor;
                        ctx.fillRect(0, 0, width, height);

                        // then punch a rounded hole out of it, toward screen center
                        var cx, cy;
                        switch (index) {
                            case 0: cx = width;  cy = height; break; // top-left corner
                            case 1: cx = 0;      cy = height; break; // top-right corner
                            case 2: cx = width;  cy = 0;      break; // bottom-left corner
                            case 3: cx = 0;      cy = 0;      break; // bottom-right corner
                        }

                        ctx.globalCompositeOperation = "destination-out";
                        ctx.beginPath();
                        ctx.arc(cx, cy, root.radius, 0, Math.PI * 2);
                        ctx.fill();
                    }

                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }
            }
        }
    }
}
