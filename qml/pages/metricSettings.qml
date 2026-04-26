import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: root
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refreshMetrics() {
        modelMetrics.clear();
        DataManager.addMetricsToModel(profileId, modelMetrics);
    }

    SilicaListView {
        anchors.fill: parent
        id: listView
        model: modelMetrics

        header: PageHeader {
            title: qsTr("Metrics")
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium

            TextSwitch {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                text: model.metricName + ' (' + (model.lastValue ? model.lastValue : '?' ) + model.metricUnit + ')'
                checked: model.is_on
                onCheckedChanged: {
                    if (checked) {
                        DataManager.addProfileMetric(root.profileId, model.id);
                    }
                    else {
                        DataManager.removeProfileMetric(root.profileId, model.id);
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: modelMetrics
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refreshMetrics();
        }
    }

    Component.onCompleted: refreshMetrics()
}

// vim:et:ts=4:sw=4
