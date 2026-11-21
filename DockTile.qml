import QtQuick
import Quickshell.Widgets
import qs.Commons as Commons

Item {
    id: tile

    property string label: ""
    property var app: null
    property string fallback: ""
    property string icon: ""
    property bool running: false
    property bool highlighted: false
    property bool muted: false
    readonly property alias hovered: hover.hovered

    signal clicked
    signal rightClicked

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: tile.clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: 15
        color: tile.highlighted ? "#537bc9f6" : tile.hovered ? "#25eef8ff" : "transparent"
        border.color: tile.highlighted ? "#a7bce7ff" : "transparent"
        Behavior on color { ColorAnimation { duration: Commons.Style.duration(130) } }
    }

    Item {
        id: iconBox
        width: tile.width - 17
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 6
        opacity: tile.muted && !tile.hovered ? 0.72 : 1
        scale: tap.pressed ? 0.94 : hover.hovered ? 1.085 : 1
        Behavior on scale {
            NumberAnimation { duration: Commons.Style.duration(150); easing.type: Easing.OutCubic }
        }

        IconImage {
            id: appIcon
            anchors.fill: parent
            source: tile.icon
            visible: status === Image.Ready
        }

        Rectangle {
            anchors.fill: parent
            visible: !appIcon.visible
            radius: 11
            color: tile.fallback === "⚙" ? "transparent" : "#606d9ab8"

            PlainLabel {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                text: tile.fallback
                color: "#edf7ff"
                font.pixelSize: tile.fallback === "⚙" ? 27 : 19
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        width: tile.highlighted ? 14 : 4
        height: 4
        radius: 2
        visible: tile.running
        color: tile.highlighted ? "#a5e8ff" : "#adc2d6"
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (eventPoint, button) => {
            if (button === Qt.RightButton)
                tile.rightClicked();
            else
                tile.clicked();
        }
    }
}
