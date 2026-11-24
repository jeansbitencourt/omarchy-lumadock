pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons as Commons

PanelWindow {
    id: panel
    required property LumaDock dock
    property bool choosingApps: false
    property real savedPinScrollY: 0
    property bool preservePinScroll: false
    readonly property var rows: {
        const installed = dock.installedApps;
        if (!choosingApps)
            return dock.pinnedIds.map(id => ({ desktopId: id, name: dock.entryLabel({ desktopId: id, name: id }) }));
        const query = search.text.trim().toLocaleLowerCase();
        return installed.filter(entry => !entry.noDisplay && (!query
            || entry.name.toLocaleLowerCase().includes(query) || entry.id.toLocaleLowerCase().includes(query)))
            .sort((left, right) => left.name.localeCompare(right.name))
            .map(entry => ({ desktopId: entry.id, name: entry.name.slice(0, 160) }));
    }

    implicitWidth: Math.min(520, screen ? screen.width - 28 : 520)
    implicitHeight: Math.min(590, screen ? screen.height - 110 : 590)
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "lumadock-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    onRowsChanged: if (preservePinScroll) scrollRestore.restart()

    function closeSettings() { dock.settingsScreen = null; }

    function movePinnedApp(desktopId, offset) {
        if (!preservePinScroll)
            savedPinScrollY = list.contentY;
        preservePinScroll = true;
        dock.movePin(desktopId, offset);
        scrollRestore.restart();
    }

    function restorePinScroll() {
        if (!preservePinScroll || choosingApps)
            return;
        const maximum = Math.max(0, list.contentHeight - list.height);
        list.contentY = Math.max(0, Math.min(savedPinScrollY, maximum));
        preservePinScroll = false;
    }

    function cancelPinScrollRestore() {
        preservePinScroll = false;
        scrollRestore.stop();
    }

    Timer {
        id: scrollRestore
        interval: 16
        repeat: false
        onTriggered: panel.restorePinScroll()
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "#fb223040"
        border.color: "#667c9bb9"
        focus: true
        Keys.onEscapePressed: panel.closeSettings()
        LayoutMirroring.enabled: Commons.I18n.rightToLeft
        LayoutMirroring.childrenInherit: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 17
            spacing: 8

            RowLayout {
                spacing: 10
                PlainLabel {
                    Layout.fillWidth: true
                    color: "#f0f7ff"
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    text: panel.dock.strings.t("settings")
                    elide: Text.ElideRight
                }
                Action {
                    label: panel.dock.strings.t("close")
                    caption: "×"
                    onClicked: panel.closeSettings()
                }
            }

            GroupLabel {
                text: panel.dock.strings.t("scope")
            }

            RowLayout {
                spacing: 6
                Action {
                    Layout.fillWidth: true
                    label: panel.dock.strings.t("all")
                    checkable: true
                    selected: !panel.dock.currentOnly
                    onClicked: panel.dock.setCurrentOnly(false)
                }
                Action {
                    Layout.fillWidth: true
                    label: panel.dock.strings.t("current")
                    checkable: true
                    selected: panel.dock.currentOnly
                    onClicked: panel.dock.setCurrentOnly(true)
                }
            }

            GroupLabel {
                text: panel.dock.strings.t("visibility")
            }

            RowLayout {
                spacing: 6
                Action {
                    Layout.fillWidth: true
                    label: panel.dock.strings.t("fixed")
                    checkable: true
                    selected: !panel.dock.autoHide
                    onClicked: panel.dock.setAutoHide(false)
                }
                Action {
                    Layout.fillWidth: true
                    label: panel.dock.strings.t("autoHide")
                    checkable: true
                    selected: panel.dock.autoHide
                    onClicked: panel.dock.setAutoHide(true)
                }
            }

            GroupLabel {
                text: panel.dock.strings.t("position")
            }

            RowLayout {
                spacing: 6
                Repeater {
                    model: panel.dock.positions
                    delegate: Action {
                        required property string modelData
                        Layout.fillWidth: true
                        label: panel.dock.strings.t(modelData)
                        checkable: true
                        selected: panel.dock.position === modelData
                        onClicked: panel.dock.setPosition(modelData)
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#4965798f"
            }

            RowLayout {
                spacing: 6
                Action {
                    Layout.fillWidth: true
                    label: panel.dock.strings.t("pins")
                    selected: !panel.choosingApps
                    onClicked: {
                        panel.cancelPinScrollRestore();
                        panel.choosingApps = false;
                        list.positionViewAtBeginning();
                    }
                }
                Action {
                    Layout.fillWidth: true
                    label: panel.dock.strings.t("apps")
                    selected: panel.choosingApps
                    onClicked: {
                        panel.cancelPinScrollRestore();
                        panel.choosingApps = true;
                        list.positionViewAtBeginning();
                        search.forceActiveFocus();
                    }
                }
            }

            Controls.TextField {
                id: search
                Layout.fillWidth: true
                Layout.preferredHeight: 33
                visible: panel.choosingApps
                color: "#eef6ff"
                placeholderTextColor: "#9eb5ca"
                placeholderText: panel.dock.strings.t("search")
                selectByMouse: true
                Keys.onEscapePressed: panel.closeSettings()
                onTextChanged: {
                    panel.cancelPinScrollRestore();
                    list.positionViewAtBeginning();
                }
                background: Rectangle {
                    color: "#90131e2a"
                    radius: 8
                    border.color: search.activeFocus ? "#a786c4ef" : "#596e8da7"
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: list
                    anchors.fill: parent
                    spacing: 4
                    model: panel.rows
                    clip: true
                    onModelChanged: if (panel.preservePinScroll) scrollRestore.restart()
                    Controls.ScrollBar.vertical: Controls.ScrollBar {}

                    delegate: Rectangle {
                        id: item
                        required property var modelData
                        required property int index
                        readonly property bool pinned: panel.dock.pinnedIds.includes(modelData.desktopId)
                        width: Math.max(0, ListView.view.width - 10)
                        height: 39
                        radius: 8
                        color: "#6361788d"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 6
                            spacing: 5
                            IconImage {
                                source: panel.dock.iconSource(item.modelData.desktopId, "")
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                            }
                            PlainLabel {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                color: "#f0f7ff"
                                text: item.modelData.name
                            }
                            Action {
                                visible: !panel.choosingApps
                                enabled: item.index > 0
                                caption: "↑"
                                label: panel.dock.strings.t("moveUp").arg(item.modelData.name)
                                onClicked: panel.movePinnedApp(item.modelData.desktopId, -1)
                            }
                            Action {
                                visible: !panel.choosingApps
                                enabled: item.index < panel.dock.pinnedIds.length - 1
                                caption: "↓"
                                label: panel.dock.strings.t("moveDown").arg(item.modelData.name)
                                onClicked: panel.movePinnedApp(item.modelData.desktopId, 1)
                            }
                            Action {
                                caption: item.pinned ? (panel.choosingApps ? "✓" : "×") : "+"
                                label: panel.dock.strings.t(item.pinned ? "remove" : "pin").arg(item.modelData.name)
                                selected: panel.choosingApps && item.pinned
                                onClicked: panel.dock.setPinned(item.modelData.desktopId, !item.pinned)
                            }
                        }
                    }
                }

                PlainLabel {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    color: "#c5d7e8"
                    text: panel.dock.strings.t(panel.choosingApps ? "noMatches" : "noPins")
                }
            }
        }
    }

    component GroupLabel: PlainLabel {
        color: "#c5d7e8"
    }

    component Action: Controls.AbstractButton {
        id: control
        property string label: ""
        property string caption: label
        property bool selected: false

        implicitWidth: Math.max(30, buttonLabel.implicitWidth + 16)
        implicitHeight: 29
        hoverEnabled: true
        Accessible.name: label
        Accessible.checkable: checkable
        Accessible.checked: selected
        background: Rectangle {
            radius: 8
            border.color: control.activeFocus ? "#b3cce8ff" : "transparent"
            color: !control.enabled ? "transparent"
                : control.down ? "#a4507b9f"
                : control.selected ? "#88608aac" : control.hovered ? "#66596e85" : "#303f5264"
        }
        contentItem: PlainLabel {
            id: buttonLabel
            text: control.caption
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: control.enabled ? "#f0f7ff" : "#8095a9"
        }
    }
}
