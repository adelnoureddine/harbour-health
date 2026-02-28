import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int metricId
    property string metricName
    property string metricUnit

    function refresh() {
        listModel.clear();
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var logs = DataManager.getLogs(profiles[0].id, metricId);
            logs.forEach(function(l) {
                listModel.append(l);
            });
        }
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("%1 History").arg(metricName)
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Entry")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    metricId: page.metricId,
                    metricName: page.metricName,
                    metricUnit: page.metricUnit
                })
            }
        }

        model: listModel

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
                anchors.verticalCenter: parent.verticalCenter
                text: model.value + " " + metricUnit
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
            text: qsTr("No data points recorded")
            hintText: qsTr("Pull down to add the first entry")
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
