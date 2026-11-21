pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons as Commons

Rectangle {
    id: panel

    required property var windows
    required property string appName
    required property string appIcon
    required property string focusedAddress
    required property string closeLabel
    required property bool vertical
    required property int availableLength
    readonly property alias hovered: panelHover.hovered
    readonly property var windowsByAddress: new Map(windows.map(window => [window.address, window]))

    property int tileWidth: 174
    property int tileHeight: 112
    readonly property int padding: 8
    readonly property int gap: 7
    readonly property int length: Math.min(availableLength, padding * 2
        + windows.length * (vertical ? tileHeight : tileWidth) + Math.max(0, windows.length - 1) * gap)

    signal selected(var window)
    signal closeRequested(var window)

    width: vertical ? tileWidth + padding * 2 : length
    height: vertical ? length : tileHeight + padding * 2
    radius: 15
    color: "#fb202c3c"
    border.color: "#8d7798b6"
    LayoutMirroring.enabled: !vertical && Commons.I18n.rightToLeft
    LayoutMirroring.childrenInherit: true

    HoverHandler { id: panelHover }

    ListView {
        id: thumbnails
        anchors.fill: parent
        anchors.margins: panel.padding
        orientation: panel.vertical ? ListView.Vertical : ListView.Horizontal
        model: ScriptModel {
            values: panel.windows.map(window => window.address)
        }
        spacing: panel.gap
        clip: true
        cacheBuffer: 0
        boundsBehavior: Flickable.StopAtBounds
        interactive: panel.vertical ? contentHeight > height : contentWidth > width

        WheelHandler {
            enabled: thumbnails.interactive
            onWheel: event => {
                const delta = event.angleDelta.y || event.angleDelta.x;
                if (panel.vertical) {
                    thumbnails.contentY = Math.max(0, Math.min(thumbnails.contentHeight - thumbnails.height,
                        thumbnails.contentY - delta / 120 * (panel.tileHeight + panel.gap)));
                } else {
                    const origin = thumbnails.originX;
                    thumbnails.contentX = Math.max(origin, Math.min(origin + thumbnails.contentWidth - thumbnails.width,
                        thumbnails.contentX - delta / 120 * (panel.tileWidth + panel.gap)));
                }
            }
        }

        delegate: Rectangle {
            id: tile
            required property string modelData
            readonly property var windowData: panel.windowsByAddress.get(modelData)
            readonly property bool focused: modelData === panel.focusedAddress
            width: panel.tileWidth
            height: panel.tileHeight
            radius: 9
            color: pointer.containsMouse ? "#526d89" : "#34475c"
            border.color: focused ? "#a5e8ff" : "#596f88"

            Accessible.role: Accessible.Button
            Accessible.name: title.text
            Accessible.onPressAction: if (tile.windowData) panel.selected(tile.windowData)

            Rectangle {
                id: imageArea
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: title.top
                anchors.margins: 5
                radius: 5
                color: "#151e2b"

                ScreencopyView {
                    id: shot
                    anchors.centerIn: parent
                    captureSource: tile.windowData?.wayland ?? null
                    constraintSize: Qt.size(imageArea.width, imageArea.height)
                    live: false
                    paintCursor: false
                    visible: hasContent
                }

                IconImage {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    source: panel.appIcon
                    visible: !shot.hasContent
                }
            }

            PlainLabel {
                id: title
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                height: 24
                elide: Text.ElideRight
                color: "#f0f7ff"
                font.pixelSize: 12
                text: String(tile.windowData?.toplevel?.title || panel.appName).slice(0, 240)
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (tile.windowData) panel.selected(tile.windowData)
            }

            Rectangle {
                width: 25
                height: 25
                x: tile.width - width - 5
                y: 5
                radius: 7
                color: closePointer.containsMouse ? "#a83748" : "#e024303f"
                border.color: "#8799a8b9"

                Accessible.role: Accessible.Button
                Accessible.name: panel.closeLabel
                Accessible.onPressAction: if (tile.windowData) panel.closeRequested(tile.windowData)

                PlainLabel {
                    anchors.fill: parent
                    text: "×"
                    color: "#ffffff"
                    font.pixelSize: 19
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                    id: closePointer
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (tile.windowData) panel.closeRequested(tile.windowData)
                }
            }
        }
    }
}
