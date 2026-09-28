import Quickshell
import QtQuick

Text {
    text: Qt.formatDateTime(clock.date, "hh:mm")
    color: "#80d4dc"

    font {
        family: "Neue Machina"
        letterSpacing: -1
        pixelSize: 18
        weight: 800
    }
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}

