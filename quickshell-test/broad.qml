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
            property int borderWidth: 5
            property color borderColor: "black" // change to your accent, e.g. "#7ecfff"

            Canvas {
                id: frame
                anchors.fill: parent

                function traceRoundedRect(ctx, x, y, w, h, r) {
                    ctx.beginPath();
                    ctx.moveTo(x + r, y);
                    ctx.lineTo(x + w - r, y);
                    ctx.arcTo(x + w, y, x + w, y + r, r);
                    ctx.lineTo(x + w, y + h - r);
                    ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
                    ctx.lineTo(x + r, y + h);
                    ctx.arcTo(x, y + h, x, y + h - r, r);
                    ctx.lineTo(x, y + r);
                    ctx.arcTo(x, y, x + r, y, r);
                    ctx.closePath();
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    // 1. fill entire screen with border color
                    ctx.fillStyle = root.borderColor;
                    ctx.fillRect(0, 0, width, height);

                    // 2. punch out an inset rounded rect, leaving only
                    //    a borderWidth-thick frame with rounded inner corners
                    ctx.globalCompositeOperation = "destination-out";
                    traceRoundedRect(
                        ctx,
                        root.borderWidth,
                        root.borderWidth,
                        width - root.borderWidth * 2,
                        height - root.borderWidth * 2,
                        root.radius
                    );
                    ctx.fill();
                }

                Component.onCompleted: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }
        }
    }
}
