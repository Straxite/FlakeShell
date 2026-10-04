import Quickshell
import QtQuick

// Calendar.qml — content-only, lives inside the pill.
// Click a day -> daySelected({y, m, d}). Click the title -> jump to today.
// Scroll wheel -> change month. Escape -> closeRequested().
//
// NOTE: this file never calls `new Date(...)`. A component named Date.qml in the same
// folder hides JavaScript's Date, which is what caused the "Jan 0" bug. All date math
// below is plain numbers, so it can't break.
Item {
    id: root

    // ---- theme (matches the pill) ----
    property color card: "#1e1e2d"       // hover / pressed circles
    property color fg: "#e8eaed"
    property color dim: "#6b6f7a"
    property color accent: "#00FFFF"     // today
    property color accentText: "#000000"
    property color weekend: "#ff5555"
    property string fontFamily: "SF Pro Display Font"

    // ---- sizing ----
    property int cell: 40
    property int gap: 2
    property int pad: 18

    // ---- today (SystemClock keeps it fresh, even past midnight) ----
    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property int todayY: clk.date.getFullYear()
    readonly property int todayM: clk.date.getMonth()      // 0-11
    readonly property int todayD: clk.date.getDate()
    readonly property var todayObj: ({ y: todayY, m: todayM, d: todayD })

    // ---- state ----
    property int viewYear: todayY
    property int viewMonth: todayM
    property var selected: null          // { y, m, d } or null

    signal daySelected(var day)
    signal closeRequested()

    focus: true
    Keys.onEscapePressed: closeRequested()
    Component.onCompleted: forceActiveFocus()

    WheelHandler {
        onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
    }

    implicitWidth: pad * 2 + cell * 7 + gap * 6
    implicitHeight: pad * 2 + header.height + 12 + weekRow.height + 6 + grid.height + 14 + footer.height

    readonly property var monthNames: ["January", "February", "March", "April", "May", "June",
                                       "July", "August", "September", "October", "November", "December"]
    readonly property var dayNames: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
    readonly property var longDays: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    // ---- date math (plain numbers, months are 0-11) ----
    function isLeap(y) { return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0 }
    function daysIn(y, m) {
        if (m === 1) return isLeap(y) ? 29 : 28
        return [3, 5, 8, 10].indexOf(m) >= 0 ? 30 : 31
    }
    // 0 = Sunday ... 6 = Saturday
    function weekday(y, m, d) {
        var t = [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]
        if (m < 2) y -= 1
        return (y + Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) + t[m] + d) % 7
    }
    // what grid cell i (0..41) shows; weeks start on Monday
    function cellDate(i) {
        var offset = (weekday(viewYear, viewMonth, 1) + 6) % 7
        var d = i - offset + 1
        var y = viewYear
        var m = viewMonth
        if (d < 1) {
            m -= 1
            if (m < 0) { m = 11; y -= 1 }
            d += daysIn(y, m)
        } else if (d > daysIn(y, m)) {
            d -= daysIn(y, m)
            m += 1
            if (m > 11) { m = 0; y += 1 }
        }
        return { y: y, m: m, d: d }
    }
    function sameDay(a, b) {
        return a && b && a.y === b.y && a.m === b.m && a.d === b.d
    }
    function shift(n) {
        var m = viewMonth + n
        var y = viewYear
        while (m < 0) { m += 12; y -= 1 }
        while (m > 11) { m -= 12; y += 1 }
        viewYear = y
        viewMonth = m
        monthFade.restart()
    }
    function goToday() {
        viewYear = todayY
        viewMonth = todayM
        selected = todayObj
        monthFade.restart()
    }
    function footerText() {
        var s = selected ? selected : todayObj
        return longDays[weekday(s.y, s.m, s.d)] + ", " + s.d + " " + monthNames[s.m]
    }

    // small fade whenever the month changes
    NumberAnimation {
        id: monthFade
        target: grid
        property: "opacity"
        from: 0.2; to: 1
        duration: 200
        easing.type: Easing.OutCubic
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.pad

        // ---------- header: ‹ Month Year › ----------
        Item {
            id: header
            width: parent.width
            height: 36

            Rectangle {
                width: 32; height: 32; radius: 16
                anchors.verticalCenter: parent.verticalCenter
                color: prevMouse.containsMouse ? root.card : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "‹"; color: root.fg
                    font.family: root.fontFamily; font.pixelSize: 22
                }
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shift(-1)
                }
            }

            Item {
                anchors.centerIn: parent
                width: title.implicitWidth + 20; height: 32
                Rectangle {
                    anchors.fill: parent; radius: 16
                    color: titleMouse.containsMouse ? root.card : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                Text {
                    id: title
                    anchors.centerIn: parent
                    text: root.monthNames[root.viewMonth] + " " + root.viewYear
                    color: root.fg
                    font.family: root.fontFamily; font.pixelSize: 16; font.bold: true
                }
                MouseArea {
                    id: titleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToday()
                }
            }

            Rectangle {
                width: 32; height: 32; radius: 16
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: nextMouse.containsMouse ? root.card : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: "›"; color: root.fg
                    font.family: root.fontFamily; font.pixelSize: 22
                }
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shift(1)
                }
            }
        }

        Item { width: 1; height: 12 }

        // ---------- weekday names ----------
        Row {
            id: weekRow
            spacing: root.gap
            Repeater {
                model: root.dayNames
                Text {
                    required property string modelData
                    required property int index
                    width: root.cell; height: 22
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: index >= 5 ? root.weekend : root.dim
                    opacity: index >= 5 ? 0.7 : 1
                    font.family: root.fontFamily; font.pixelSize: 12; font.bold: true
                }
            }
        }

        Item { width: 1; height: 6 }

        // ---------- day grid ----------
        Grid {
            id: grid
            columns: 7
            spacing: root.gap

            Repeater {
                model: 42
                Item {
                    id: dayCell
                    required property int index
                    readonly property var info: root.cellDate(index)
                    readonly property bool inMonth: info.m === root.viewMonth
                    readonly property bool isToday: root.sameDay(info, root.todayObj)
                    readonly property bool isSel: root.sameDay(info, root.selected)
                    readonly property bool isWeekend: index % 7 >= 5

                    width: root.cell; height: root.cell

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cell - 4; height: root.cell - 4
                        radius: width / 2
                        color: dayCell.isToday ? root.accent
                             : dayMouse.containsMouse ? root.card : "transparent"
                        border.width: dayCell.isSel && !dayCell.isToday ? 2 : 0
                        border.color: root.accent
                        scale: dayMouse.pressed ? 0.88 : 1
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.info.d
                            font.family: root.fontFamily
                            font.pixelSize: 14
                            font.bold: dayCell.isToday
                            color: dayCell.isToday ? root.accentText
                                 : !dayCell.inMonth ? root.dim
                                 : dayCell.isWeekend ? root.weekend : root.fg
                            opacity: dayCell.inMonth ? 1 : 0.5
                        }
                    }

                    MouseArea {
                        id: dayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selected = dayCell.info
                            root.daySelected(dayCell.info)
                            // clicked a greyed-out day? jump to its month
                            if (!dayCell.inMonth) {
                                root.viewYear = dayCell.info.y
                                root.viewMonth = dayCell.info.m
                                monthFade.restart()
                            }
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 14 }

        // ---------- footer: selected date ----------
        Text {
            id: footer
            width: parent.width
            height: 20
            horizontalAlignment: Text.AlignHCenter
            text: root.footerText()
            color: root.dim
            font.family: root.fontFamily; font.pixelSize: 12
        }
    }
}
