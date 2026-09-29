import Quickshell
import QtQuick

Rectangle {
  id: root
  property bool hovered: false

  implicitHeight: 30
  implicitWidth: 90
  color: "transparent"

  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenter: parent.verticalCenter
  anchors.verticalCenterOffset: root.hovered ? 20 : 0

  Behavior on anchors.verticalCenterOffset {
    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
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

// For the day and month

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? -35 : 0
    anchors.verticalCenterOffset: root.hovered ? 3 : 0
    text: Qt.formatDateTime(clock.date, "ddd, MMM")
    color: "#e8eaed"
    opacity: root.hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 14; weight: 700 }
  }

// for yesterday date

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 0 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(-1)
    color: "#FF0000"
    opacity: root.hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 12; weight: 700 }
  }

// for current date
Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 25 : 0
    anchors.verticalCenterOffset: root.hovered ? 5 : 0
    color: "#1e1e4d"
    radius: 6
    implicitHeight: pill.isHovered ? 28 : 0
    implicitWidth: pill.isHovered ? 22 : 0
    Text {
      anchors.centerIn: parent
    text: root.dayOffset(0)
    color: "#e8eaed"
    opacity: root.hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 16; weight: 900 }
  }
}

// for tomorrow date

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.horizontalCenterOffset: root.hovered ? 48 : 0
    anchors.verticalCenterOffset: root.hovered ? 4.5 : 0
    text: root.dayOffset(1)
    color: "#32cd32"
    opacity: root.hovered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    font { family: "SF Pro Display Font"; letterSpacing: -1; pixelSize: 12; weight: 700 }
  }
}
