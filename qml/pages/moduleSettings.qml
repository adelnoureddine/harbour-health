import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Arrange dashboard: every card in the order the dashboard shows it, with a switch to
 * show or hide it and buttons to move it. Long-pressing a card offers moving it to the
 * top in one go, rather than a step at a time. The order is saved per profile as soon
 * as a card moves.
 */
Page {
    id: root
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refreshModules() {
        modelModules.clear();
        DataManager.addModulesToModel(root.profileId, modelModules, false);
    }

    function saveOrder() {
        var ids = [];
        for (var i = 0; i < modelModules.count; i++) {
            ids.push(modelModules.get(i).id);
        }
        DataManager.setModuleOrder(root.profileId, ids);
    }

    function move(from, to) {
        if (to < 0 || to >= modelModules.count) {
            return;
        }
        modelModules.move(from, to, 1);
        saveOrder();
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: modelModules

        header: Column {
            width: listView.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Arrange dashboard")
                description: qsTr("Order the cards and choose which are shown")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Long-press a card to move it straight to the top.")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Reset to default order")
                onClicked: resetRemorse.execute(qsTr("Resetting order"), function() {
                    DataManager.resetModuleOrder(root.profileId);
                    root.refreshModules();
                })
            }
        }

        move: Transition {
            NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.InOutQuad }
        }
        moveDisplaced: Transition {
            NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.InOutQuad }
        }

        delegate: ListItem {
            id: row
            width: listView.width
            contentHeight: Math.max(Theme.itemSizeMedium, moduleSwitch.height)

            // Set from the menu and acted on once it has closed: moving the row while
            // its menu is still open would move the open menu along with it.
            property bool toTop: false

            menu: Component {
                ContextMenu {
                    onClosed: {
                        if (row.toTop) {
                            row.toTop = false;
                            root.move(index, 0);
                            listView.positionViewAtBeginning();
                        }
                    }
                    MenuItem {
                        text: qsTr("Move to top")
                        enabled: index > 0
                        onClicked: row.toTop = true
                    }
                }
            }

            /*
             * automaticCheck/onClicked rather than onCheckedChanged: the latter also fired
             * while the delegate was being built and again while the model was being
             * cleared, so simply opening this page rewrote every row -- and leaving it
             * could silently switch modules back off.
             */
            TextSwitch {
                id: moduleSwitch
                anchors.left: parent.left
                anchors.right: buttons.left
                anchors.verticalCenter: parent.verticalCenter
                text: Utils.moduleDisplayName(model.name)
                checked: model.is_on
                automaticCheck: false
                // The switch covers most of the row, so it opens the row's menu itself.
                onPressAndHold: row.openMenu()

                onClicked: {
                    var enabled = !checked;
                    if (enabled) {
                        DataManager.addProfileModule(root.profileId, model.id);
                    } else {
                        DataManager.removeProfileModule(root.profileId, model.id);
                    }
                    modelModules.setProperty(index, "is_on", enabled ? 1 : 0);
                }
            }

            Row {
                id: buttons
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin - Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter

                IconButton {
                    icon.source: "image://theme/icon-m-up"
                    enabled: index > 0
                    onClicked: root.move(index, index - 1)
                }
                IconButton {
                    icon.source: "image://theme/icon-m-down"
                    enabled: index < modelModules.count - 1
                    onClicked: root.move(index, index + 1)
                }
            }
        }

        VerticalScrollDecorator {}
    }

    RemorsePopup {
        id: resetRemorse
    }

    ListModel {
        id: modelModules
    }

    Component.onCompleted: refreshModules()
}

// vim:et:ts=4:sw=4
