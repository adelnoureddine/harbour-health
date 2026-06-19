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
            title: qsTr("Modules")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Metric settings")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("metricSettings.qml"), {
                    profileId: root.profileId
                })
            }

            MenuItem {
                    text: qsTr("Cover page settings")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("coverSettings.qml"), {
                        profileId: root.profileId
                    })
                }
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium
            onClicked: {
                DataManager.useProfile(model.id);
                pageStack.pop();
            }
            TextSwitch {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin

                text: model.name
                checked: model.is_on
                onCheckedChanged: {
                    if (checked) {
                        DataManager.addProfileModule(root.profileId, model.id);
                    }
                    else {
                        DataManager.removeProfileModule(root.profileId, model.id);
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: modelModules
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refreshModules();
        }
    }

    Component.onCompleted: refreshModules()
}

// vim:et:ts=4:sw=4
