import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: root
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refreshModules() {
        modelModules.clear();
        DataManager.addModulesToModel(root.profileId, modelModules, false);
    }

    SilicaListView {
        anchors.fill: parent
        id: listView
        model: modelModules

        header: PageHeader {
            width: listView.width
            title: qsTr("Modules")
            description: qsTr("Choose what appears on your dashboard")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Cover page settings")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("coverSettings.qml"), {
                    profileId: root.profileId
                })
            }
        }

        section {
            property: "category"
            criteria: ViewSection.FullString
            delegate: SectionHeader { text: section }
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium

            /*
             * automaticCheck/onClicked rather than onCheckedChanged: the latter also
             * fired while the delegate was being built and again while the model was
             * being cleared, so simply opening this page rewrote every row -- and
             * leaving it could silently switch modules back off.
             */
            TextSwitch {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                text: model.name
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
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: modelModules
    }

    Component.onCompleted: refreshModules()
}

// vim:et:ts=4:sw=4
