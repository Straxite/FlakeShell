import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    property color barColor: "#ffffff"
    property int barWidth: 3
    property int barGap: 3
    property int maxHeight: 16

    width: (barWidth * 3) + (barGap * 2)
    height: maxHeight

    property var levels: [0.25, 0.45, 0.3]

    Process {
        id: cava

        command: [
            "cava",
            "-p", cavaConfig.path
        ]

        running: true

        stdout: SplitParser {
            onRead: data => {
                let values = data.trim().split(";")

                if (values.length >= 3) {
                    root.levels = [
                        Math.max(0.08, Math.min(1, Number(values[0]) / 100)),
                        Math.max(0.08, Math.min(1, Number(values[1]) / 100)),
                        Math.max(0.08, Math.min(1, Number(values[2]) / 100))
                    ]
                }
            }
        }
    }

    FileView {
        id: cavaConfig

        path: "/tmp/quickshell-cava.conf"

        blockLoading: true

        onLoaded: {
            reload()
        }

        Component.onCompleted: {
            write(
                "[general]\n" +
                "bars = 3\n" +
                "framerate = 60\n" +
                "autosens = 1\n" +
                "sensitivity = 100\n" +
                "\n" +
                "[output]\n" +
                "method = raw\n" +
                "raw_target = /dev/stdout\n" +
                "data_format = ascii\n" +
                "ascii_max_range = 100\n" +
                "bar_delimiter = ;\n" +
                "\n" +
                "[smoothing]\n" +
                "noise_reduction = 0\n"
            )
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.barGap

        Repeater {
            model: 3

            Rectangle {
                width: root.barWidth

                height: root.levels[index] * root.maxHeight

                anchors.verticalCenter: parent.verticalCenter

                radius: width / 2

                color: root.barColor

                Behavior on height {
                    NumberAnimation {
                        duration: 70
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
