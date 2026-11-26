import QtQuick
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
    required property var theme
    readonly property alias hovered: hover.hovered

    signal clicked
    signal rightClicked

    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: tile.clicked()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: tile.theme.tile.radius
        color: tile.highlighted ? tile.theme.tile.active : tile.hovered ? tile.theme.tile.hover : "transparent"
        border.color: tile.highlighted ? tile.theme.tile.activeBorder : "transparent"
        Behavior on color { ColorAnimation { duration: Commons.Style.duration(130) } }
    }

    Item {
        id: iconBox
        width: tile.width - 17
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 6
        clip: true
        opacity: tile.muted && !tile.hovered ? 0.72 : 1
        scale: tap.pressed ? 0.94 : hover.hovered ? 1.085 : 1
        Behavior on scale {
            NumberAnimation { duration: Commons.Style.duration(150); easing.type: Easing.OutCubic }
        }

        NormalizedIcon {
            id: appIcon
            anchors.fill: parent
            source: tile.icon
        }

        Rectangle {
            anchors.fill: parent
            visible: !appIcon.ready
            radius: 11
            color: tile.fallback === "⚙" ? "transparent" : tile.theme.tile.fallbackBg

            PlainLabel {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                text: tile.fallback
                color: tile.theme.tile.fallbackText
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
        color: tile.highlighted ? tile.theme.tile.indicatorActive : tile.theme.tile.indicator
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
