import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick
import QtQuick.Effects

WlSessionLock {
  id: lock

  property string userName: Quickshell.env("USER")
  property string userFace: "file://" + Quickshell.env("HOME") + "/.face"

  locked: false

  WlSessionLockSurface {
    id: surface
    color: "black"

    property string buffer: ""
    property bool failed: false
    property bool checking: false
    readonly property bool typing: input.text.length > 0 || checking

    PamContext {
      id: pam
      config: "login"
      onPamMessage: if (responseRequired) respond(surface.buffer)
      onCompleted: result => {
        surface.checking = false
        surface.buffer = ""
        if (result === PamResult.Success) {
          leave.start()
        } else {
          surface.failed = true
          input.text = ""
          shake.restart()
        }
      }
    }

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    Item {
      id: content
      anchors.fill: parent

      property real blurAmt: 0
      property real clockAppear: 0
      property real userAppear: 0

      Component.onCompleted: {
        enter.start()
        input.forceActiveFocus()
      }

      ParallelAnimation {
        id: enter
        NumberAnimation { target: content; property: "blurAmt"; to: 1; duration: 600; easing.type: Easing.OutCubic }
        SequentialAnimation {
          PauseAnimation { duration: 150 }
          NumberAnimation { target: content; property: "clockAppear"; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
          PauseAnimation { duration: 300 }
          NumberAnimation { target: content; property: "userAppear"; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
      }

      SequentialAnimation {
        id: leave
        ParallelAnimation {
          NumberAnimation { target: content; property: "clockAppear"; to: 0; duration: 300; easing.type: Easing.InCubic }
          NumberAnimation { target: content; property: "userAppear"; to: 0; duration: 300; easing.type: Easing.InCubic }
          NumberAnimation { target: content; property: "blurAmt"; to: 0; duration: 450; easing.type: Easing.InOutCubic }
        }
        ScriptAction { script: lock.locked = false }
      }

      ScreencopyView {
        anchors.fill: parent
        captureSource: surface.screen
        layer.enabled: true
        layer.effect: MultiEffect {
          autoPaddingEnabled: false
          blurEnabled: true
          blur: content.blurAmt
          blurMax: 64
          saturation: 0.2 * content.blurAmt
        }
      }

      Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.18 * content.blurAmt
      }

      Column {
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.07
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: -8
        opacity: content.clockAppear
        transform: Translate { y: (1 - content.clockAppear) * -30 }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(clock.date, "dddd d MMMM")
          color: "#d9ffffff"
          font.family: "SF Pro Display"
          font.pixelSize: 24
          font.weight: Font.Medium
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDateTime(clock.date, "h:mm")
          color: "#f2ffffff"
          font.family: "SF Pro Display"
          font.pixelSize: 140
          font.weight: Font.DemiBold
        }
      }

      Column {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.07
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12
        opacity: content.userAppear
        transform: Translate { y: (1 - content.userAppear) * 40 }

        Item {
          width: 84
          height: 84
          anchors.horizontalCenter: parent.horizontalCenter

          Rectangle {
            id: avatarMask
            anchors.fill: parent
            radius: width / 2
            visible: false
            layer.enabled: true
          }

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#59ffffff"
            visible: faceImage.status !== Image.Ready

            Text {
              anchors.centerIn: parent
              text: lock.userName.length > 0 ? lock.userName.charAt(0).toUpperCase() : "?"
              color: "white"
              font.family: "SF Pro Display"
              font.pixelSize: 38
              font.weight: Font.Medium
            }
          }

          Image {
            id: faceImage
            anchors.fill: parent
            source: lock.userFace
            sourceSize: Qt.size(168, 168)
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: MultiEffect {
              maskEnabled: true
              maskSource: avatarMask
              maskThresholdMin: 0.5
              maskSpreadAtMin: 1.0
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: lock.userName
          color: "white"
          font.family: "SF Pro Display"
          font.pixelSize: 18
          font.weight: Font.Medium
        }

        Item {
          width: 300
          height: 36
          anchors.horizontalCenter: parent.horizontalCenter

          Text {
            anchors.centerIn: parent
            text: surface.failed ? "Incorrect password" : "Enter Password"
            color: surface.failed ? "#ff8f8f" : "#b3ffffff"
            font.family: "SF Pro Display"
            font.pixelSize: 14
            opacity: surface.typing ? 0 : 1

            Behavior on opacity {
              NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
          }

          Item {
            id: area
            anchors.fill: parent
            opacity: surface.checking ? 0.55 : 1

            property int alive: 0
            property int tick: 0
            readonly property real gap: Math.min(20, (width - 20) / Math.max(1, alive))

            Behavior on opacity {
              NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            transform: Translate { id: shiftT }

            ListModel { id: dotModel }

            function slotOf(i) {
              let c = 0
              for (let j = 0; j < i && j < dotModel.count; j++)
                if (!dotModel.get(j).dying) c++
              return c
            }

            function sync(n) {
              while (alive < n) {
                dotModel.append({ dying: false })
                alive++
              }
              while (alive > n) {
                for (let i = dotModel.count - 1; i >= 0; i--) {
                  if (!dotModel.get(i).dying) {
                    dotModel.setProperty(i, "dying", true)
                    break
                  }
                }
                alive--
              }
              tick++
            }

            SequentialAnimation {
              id: shake
              NumberAnimation { target: shiftT; property: "x"; to: -12; duration: 50 }
              NumberAnimation { target: shiftT; property: "x"; to: 12; duration: 80 }
              NumberAnimation { target: shiftT; property: "x"; to: -8; duration: 70 }
              NumberAnimation { target: shiftT; property: "x"; to: 8; duration: 60 }
              NumberAnimation { target: shiftT; property: "x"; to: 0; duration: 50 }
            }

            Repeater {
              model: dotModel

              Rectangle {
                id: dot

                required property int index
                required property bool dying

                property real p: 0
                readonly property int slot: { area.tick; return area.slotOf(index) }

                width: 11
                height: 11
                radius: 6
                color: "white"
                opacity: Math.min(1, p)
                scale: p
                x: area.width / 2 + (slot - (area.alive - 1) / 2) * area.gap - width / 2
                y: (area.height - height) / 2 + (1 - Math.min(1, p)) * 8

                Behavior on x {
                  NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                Component.onCompleted: appear.start()

                onDyingChanged: if (dying) {
                  appear.stop()
                  vanish.start()
                }

                NumberAnimation {
                  id: appear
                  target: dot
                  property: "p"
                  to: 1
                  duration: 300
                  easing.type: Easing.OutBack
                  easing.overshoot: 2.2
                }

                SequentialAnimation {
                  id: vanish
                  PauseAnimation { duration: Math.min(dot.index, 10) * 22 }
                  NumberAnimation { target: dot; property: "p"; to: 0; duration: 170; easing.type: Easing.InCubic }
                  ScriptAction { script: dotModel.remove(dot.index) }
                }
              }
            }
          }
        }
      }

      TextInput {
        id: input
        width: 1
        height: 1
        opacity: 0
        echoMode: TextInput.Password
        enabled: !surface.checking
        focus: true

        onTextChanged: {
          if (text.length > 0) surface.failed = false
          area.sync(text.length)
        }

        Keys.onEscapePressed: text = ""

        onAccepted: {
          if (text.length === 0 || surface.checking) return
          surface.buffer = text
          surface.checking = true
          pam.start()
        }
      }
    }
  }
}
