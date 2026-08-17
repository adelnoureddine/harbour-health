
import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int metricId: -1
    property string metricName: qsTr("History")

    function refresh() {
        if (profileId === -1) {
            var profiles = DataManager.getProfiles();
            if (profiles.length > 0) profileId = profiles[0].id;
        }

        if (profileId !== -1) {
            var logs = DataManager.getLogs(profileId, metricId);
            listModel.clear();
            for (var i = 0; i < logs.length; i++) {
                listModel.append(logs[i]);
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: PageHeader {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            title: metricName
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Entry")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    metricId: page.metricId,
                    metricName: page.metricName
                })
            }
        }

        delegate: ListItem {
            id: listItem
            contentHeight: Theme.itemSizeSmall

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: {
                        listItem.remorseDelete(function() {
                            DataManager.deleteLog(model.id);
                            refresh();
                        })
                    }
                }
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.value
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            
            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.timestamp
                font.pixelSize: Theme.fontSizeExtraSmall
                color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No data recorded")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}
