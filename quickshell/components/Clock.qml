import Quickshell
import QtQuick

Rectangle {
  implicitHeight: 30
  implicitWidth: 90
  color: "transparent"

  anchors.horizontalCenter: parent.horizontalCenter
  anchors.verticalCenter: parent.verticalCenter
  anchors.verticalCenterOffset: pill.isHovered ? -10 : 0
  anchors.horizontalCenterOffset: pill.isHovered ? 0 : 0

  Behavior on anchors.verticalCenterOffset {
    NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
  }
  Text {
    anchors.centerIn: parent
      text: Qt.formatDateTime(clock.date, "hh:mm")
      color: "#e8eaed"

      font {
          family: "SF Pro Display Font"
          letterSpacing: -1
          pixelSize: pill.isHovered ? 30 : 18
          weight: 700

          Behavior on pixelSize {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
          }
      }
      SystemClock {
          id: clock
          precision: SystemClock.Minutes
      }
  }
}
