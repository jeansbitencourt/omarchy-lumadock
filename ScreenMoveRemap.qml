import QtQuick

Item {
    id: root

    required property var screen
    property bool remapping: false

    visible: false

    onScreenChanged: settleTimer.stop()

    // Let successive changes to the monitor's origin settle before unmapping.
    Timer {
        id: settleTimer
        interval: 200
        onTriggered: root.remapping = true
    }

    // Keep the surfaces unmapped long enough for the compositor to see it.
    Timer {
        interval: 50
        running: root.remapping
        onTriggered: root.remapping = false
    }

    Connections {
        target: root.screen
        function onXChanged() { settleTimer.restart() }
        function onYChanged() { settleTimer.restart() }
    }
}
