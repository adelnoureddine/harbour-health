import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metric1: DataManager.METRIC_WEIGHT
    property string metric2: DataManager.METRIC_WATER

    function loadMetrics() {
        metricModel.clear();
        var metrics = DataManager.getMetrics();
        for (var i = 0; i < metrics.length; i++) {
            metricModel.append({ name: metrics[i].name });
        }
    }

    function indexOfMetric(name) {
        for (var i = 0; i < metricModel.count; i++) {
            if (metricModel.get(i).name === name) {
                return i;
            }
        }
        return 0;
    }

    function refresh() {
        var metrics = DataManager.getCoverMetrics(profileId);
        metric1 = metrics.metric1;
        metric2 = metrics.metric2;
        // Set after the model is populated, otherwise there is nothing to select.
        metric1Combo.currentIndex = indexOfMetric(metric1);
        metric2Combo.currentIndex = indexOfMetric(metric2);
    }

    function save() {
        DataManager.updateCoverMetrics(profileId, metric1, metric2);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Cover Page Settings")
            }

            SectionHeader {
                text: qsTr("Metrics to display")
            }

            ComboBox {
                id: metric1Combo
                width: parent.width
                label: qsTr("First metric")
                menu: ContextMenu {
                    Repeater {
                        model: metricModel
                        MenuItem {
                            text: Utils.metricDisplayName(model.name)
                            onClicked: {
                                page.metric1 = model.name;
                                page.save();
                            }
                        }
                    }
                }
            }

            ComboBox {
                id: metric2Combo
                width: parent.width
                label: qsTr("Second metric")
                menu: ContextMenu {
                    Repeater {
                        model: metricModel
                        MenuItem {
                            text: Utils.metricDisplayName(model.name)
                            onClicked: {
                                page.metric2 = model.name;
                                page.save();
                            }
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Preview")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("The cover will show %1 and %2.")
                        .arg(Utils.metricDisplayName(metric1))
                        .arg(Utils.metricDisplayName(metric2))
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                visible: metric1 === metric2
                text: qsTr("Both slots show the same metric.")
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel { id: metricModel }

    Component.onCompleted: {
        loadMetrics();
        refresh();
    }
}

// vim:et:ts=4:sw=4
