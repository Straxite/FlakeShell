import Quickshell
import QtQuick
import qs

Rectangle {
  id: root
  property bool hovered: false
  signal clicked()   // Pill.qml listens to this to open the calendar

    Rectangle {
            implicitHeight: 30
            implicitWidth: 90
            color: "transparent"

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: pill.isHovered ? -30 : 0
            anchors.horizontalCenterOffset: pill.isHovered ? 0 : 0

            Behavior on anchors.verticalCenterOffset {
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }
            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "hh:mm")
                color: "#e8eaed"

            font {
                family: "SF Pro Display RoundedFont"
                letterSpacing: -1
                pixelSize: pill.isHovered ? 30 : 18
                weight: 700

                    Behavior on pixelSize {
                        NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
                    }
                }
            }
        }

  implicitHeight: 120
  implicitWidth: 320
  color: root.isHovered ? "transparent" : (area.containsMouse ? Colors.surfaceContainerLowest : "transparent")

  Behavior on color {
    ColorAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  opacity: root.isHovered ? 0 : (area.containsMouse ? 1 : 1)

  radius: 16

  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenter: parent.verticalCenter
  anchors.verticalCenterOffset: root.hovered ? 0 : 0

  Behavior on anchors.verticalCenterOffset {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  function daysIn(y, m) {   // m is 0-11
    if (m === 1) return ((y % 4 === 0 && y % 100 !== 0) || y % 400 === 0) ? 29 : 28
    return [3, 5, 8, 10].indexOf(m) >= 0 ? 30 : 31
  }

  function dayOffset(n) {
    const d = clock.date
    let y = d.getFullYear()
    let m = d.getMonth()
    let day = d.getDate() + n

    if (day < 1) {
      m -= 1
      if (m < 0) { m = 11; y -= 1 }
      day += daysIn(y, m)
    } else if (day > daysIn(y, m)) {
      day -= daysIn(y, m)
    }
    return day < 10 ? "0" + day : "" + day
  }

  function dayName(n) {
  const names = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
  return names[((clock.date.getDay() + n) % 7 + 7) % 7]
  }
  function isSunday(n) {
  return ((clock.date.getDay() + n) % 7 + 7) % 7 === 0
  }

Item {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 0 : 0
    anchors.verticalCenterOffset: root.hovered ? 20 : 0
Item {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 0 : 0
    anchors.verticalCenterOffset: root.hovered ? 0 : 0

    Rectangle {
      implicitHeight: pill.isHovered ? 50 : 0
      implicitWidth: pill.isHovered ? 38 : 0
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter
      anchors.verticalCenterOffset: 4
      anchors.horizontalCenterOffset: 1
      radius: 16
      color: "#1e1e2d"
    }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? -92 : 0
    anchors.verticalCenterOffset: root.hovered ? -4 : 0
    text: root.dayName(-3)
    color: root.isSunday(-3) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.2 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 8; weight: 700 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? -68 : 0
    anchors.verticalCenterOffset: root.hovered ? -6 : 0
    text: root.dayName(-2)
    color: root.isSunday(-2) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.6 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 12; weight: 700 }
  }
  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? -38 : 0
    anchors.verticalCenterOffset: root.hovered ? -8 : 0
    text: root.dayName(-1)
    color: root.isSunday(-1) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.8 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 14; weight: 700 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 0 : 0
    anchors.verticalCenterOffset: root.hovered ? -10 : 0
    text: Qt.formatDateTime(clock.date, "ddd")
    color: "#e8eaed"
    opacity: root.hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 14; weight: 700 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 38 : 0
    anchors.verticalCenterOffset: root.hovered ? -8 : 0
    text: root.dayName(1)
    color: root.isSunday(1) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.8 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 14; weight: 700 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 68 : 0
    anchors.verticalCenterOffset: root.hovered ? -6 : 0
    text: root.dayName(2)
    color: root.isSunday(2) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.6 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 10; weight: 700 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 94 : 0
    anchors.verticalCenterOffset: root.hovered ? -4 : 0
    text: root.dayName(3)
    color: root.isSunday(3) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.2 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 8; weight: 700 }
  }
}

// for yesterday date
Item {
  anchors.horizontalCenter: parent.horizontalCenter
  anchors.horizontalCenterOffset: -24
  anchors.verticalCenter: parent.verticalCenter
  anchors.verticalCenterOffset: 10

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? -68 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(-3)
    color: root.isSunday(-3) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.2 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 14; weight: 500 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? -42 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(-2)
    color: root.isSunday(-2) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.6 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 16; weight: 500 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? -14 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(-1)
    color: root.isSunday(-1) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.8 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 20; weight: 500 }
  }

// for current date
Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 25 : 0
    anchors.verticalCenterOffset: root.hovered ? 5 : 0
    color: "transparent"
    radius: 6
    implicitHeight: pill.isHovered ? 28 : 0
    implicitWidth: pill.isHovered ? 22 : 0
    Text {
      anchors.centerIn: parent
    text: root.dayOffset(0)
    color: "#00FFFF"
    opacity: root.hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 24; weight: 700 }
  }
}

// for tomorrow date

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 64 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(1)
    color: root.isSunday(1) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.8 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 20; weight: 500 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 94 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(2)
    color: root.isSunday(2) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.6 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 16; weight: 500 }
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 118 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(3)
    color: root.isSunday(3) ? "#ff5555" : "#e8eaed"
    opacity: root.hovered ? 0.2 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 14; weight: 500 }
  }
}
}
}
