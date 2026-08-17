import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property bool grouped: false
    property string metricName
    property string metricUnit
    property var invalidateSignal

    function refresh() {
        listModel.clear();
        DataManager.addLogsToModel(profileId, metricName, listModel, page.grouped);
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            title: qsTr("%1 History").arg(metricName)
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Constraints")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("metricConstraints.qml"), {
                    profileId: profileId,
                    metricName: page.metricName
                })
            }
            MenuItem {
                text: qsTr("Add Entry")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: profileId,
                    metricName: page.metricName,
                    metricUnit: page.metricUnit,
                    invalidateSignal: invalidateSignal
                })
            }
        }

        model: listModel

        section {
            property: "day"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: DataManager.filteredSumFromModel(ListView.view.model, {day: section}, "value") + page.metricUnit + " - " + section
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
                            listModel.remove(index);
                            if (page.invalidateSignal) {
                                page.invalidateSignal(page.metricName);
                            }
                        })
                    }
                }
            }
            
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.value + " " + metricUnit
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: grouped ? model.timestamp.split('T')[1].split(':').slice(0, 2).join(':') : model.timestamp.replace('T', ' ')
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

// vim:et:ts=4:sw=4
