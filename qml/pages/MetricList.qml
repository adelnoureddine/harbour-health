import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: metricList
    allowedOrientations: Orientation.All

    function refresh() {
        listModel.clear();
        var metrics = DataManager.getMetrics();
        metrics.forEach(function(m) {
            listModel.append(m);
        });
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            title: qsTr("Health Metrics")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Dashboard")
                onClicked: pageStack.pop()
            }
        }

        model: listModel

        delegate: ListItem {
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("MetricDetails.qml"), {
                    metricId: model.id,
                    metricName: model.name,
                    metricUnit: model.unit
                })
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr(model.name)
                color: Theme.primaryColor
                font.capitalization: Font.Capitalize
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.unit
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
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
