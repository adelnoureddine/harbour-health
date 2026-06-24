import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName1
    property string metricName2
    property string metricUnit: "mmHg"
    property var invalidateSignal

    function refresh() {
        listModel.clear();
        var logs1 = [];
        var logs2 = [];
        DataManager.addLogsToModel(profileId, metricName1, {append: function(o){ logs1.push(o); }}, false);
        DataManager.addLogsToModel(profileId, metricName2, {append: function(o){ logs2.push(o); }}, false);

        var usedIndexes = [];
        for (var i = 0; i < logs1.length; i++) {
            var log1 = logs1[i];
            var log2 = null;
            var log2Index = -1;
            var ts1 = log1.timestamp.substring(0, 16);
            var bestDiff = 999999;

            for (var j = 0; j < logs2.length; j++) {
                if (usedIndexes.indexOf(j) >= 0) continue;
                var ts2 = logs2[j].timestamp.substring(0, 16);
                if (ts2 === ts1) {
                    var t1 = new Date(log1.timestamp).getTime();
                    var t2 = new Date(logs2[j].timestamp).getTime();
                    var diff = Math.abs(t1 - t2);
                    if (diff < bestDiff) {
                        bestDiff = diff;
                        log2 = logs2[j];
                        log2Index = j;
                    }
                }
            }

            if (log2Index >= 0) usedIndexes.push(log2Index);

            listModel.append({
                id1: log1.id,
                id2: log2 ? log2.id : -1,
                value1: log1.value,
                value2: log2 ? log2.value : "?",
                timestamp: log1.timestamp,
                day: log1.day
            });
        }
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Blood Pressure History")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Entry")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMultiMetric.qml"), {
                    profileId: page.profileId,
                    metricName1: page.metricName1,
                    metricName2: page.metricName2,
                    metricUnit: page.metricUnit,
                    invalidateSignal: page.invalidateSignal
                })
            }
        }

        model: listModel

        section {
            property: "day"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                text: section
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
                            DataManager.deleteLog(model.id1);
                            if (model.id2 >= 0) DataManager.deleteLog(model.id2);
                            listModel.remove(index);
                            if (page.invalidateSignal) {
                                page.invalidateSignal(page.metricName1);
                            }
                        })
                    }
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Label {
                    text: model.value1 + " / " + model.value2 + " " + page.metricUnit
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeMedium
                }
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.timestamp.replace('T', ' ')
                color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No blood pressure recorded")
            hintText: qsTr("Pull down to add an entry")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) refresh();
    }

    Component.onCompleted: refresh()
}
