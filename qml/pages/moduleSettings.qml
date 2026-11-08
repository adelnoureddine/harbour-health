import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Arrange dashboard: every card in the order the dashboard shows it, with a switch to
 * show or hide it and buttons to move it. The order is saved per profile as soon as
 * a card moves.
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

        header: PageHeader {
            width: listView.width
            title: qsTr("Arrange dashboard")
            description: qsTr("Order the cards and choose which are shown")
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

        delegate: Item {
            id: row
            width: listView.width
            height: Math.max(Theme.itemSizeMedium, moduleSwitch.height)

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
