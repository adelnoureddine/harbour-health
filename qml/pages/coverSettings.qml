import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metric1: "weight"
    property string metric2: "water"

    function refresh() {
        var metrics = DataManager.getCoverMetrics(profileId);
        metric1 = metrics.metric1;
        metric2 = metrics.metric2;
        metric1Combo.updateSelection();
        metric2Combo.updateSelection();
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            Item {
                width: parent.width
                height: childrenRect.height

                PageHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    title: qsTr("Cover Page Settings")
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height

                SectionHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Metrics to display")
                }
            }

            ComboBox {
                id: metric1Combo
                width: parent.width
                label: qsTr("First metric")

                function updateSelection() {
                    var metrics = DataManager.getMetrics();
                    metricModel1.clear();
                    for (var i = 0; i < metrics.length; i++) {
                        metricModel1.append({ name: metrics[i].name });
                        if (metrics[i].name === page.metric1) {
                            currentIndex = i;
                        }
                    }
                }

                menu: ContextMenu {
                    Repeater {
                        model: ListModel { id: metricModel1 }
                        MenuItem {
                            text: model.name
                            onClicked: {
                                page.metric1 = model.name;
                                DataManager.updateCoverMetrics(page.profileId, page.metric1, page.metric2);
                            }
                        }
                    }
                }
            }

            ComboBox {
                id: metric2Combo
                width: parent.width
                label: qsTr("Second metric")

                function updateSelection() {
                    var metrics = DataManager.getMetrics();
                    metricModel2.clear();
                    for (var i = 0; i < metrics.length; i++) {
                        metricModel2.append({ name: metrics[i].name });
                        if (metrics[i].name === page.metric2) {
                            currentIndex = i;
                        }
                    }
                }

                menu: ContextMenu {
                    Repeater {
                        model: ListModel { id: metricModel2 }
                        MenuItem {
                            text: model.name
                            onClicked: {
                                page.metric2 = model.name;
                                DataManager.updateCoverMetrics(page.profileId, page.metric1, page.metric2);
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: childrenRect.height

                SectionHeader {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    text: qsTr("Preview")
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeSmall
                text: qsTr("The cover page will display: %1 and %2").arg(metric1).arg(metric2)
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) refresh();
    }

    Component.onCompleted: refresh()
}
