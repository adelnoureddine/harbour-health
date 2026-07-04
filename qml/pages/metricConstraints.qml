import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName: ""

    function refresh() {
        listModel.clear();
        var constraints = DataManager.getConstraintsForMetric(metricName);
        constraints.forEach(function(c) {
            listModel.append(c);
        });
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Constraints — %1").arg(metricName)
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Constraint")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addConstraint.qml"), {
                    metricName: page.metricName,
                    invalidate: function() { page.refresh(); }
                })
            }
        }

        model: listModel

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: remorseDelete(function() {
                        DataManager.deleteConstraint(model.id);
                        listModel.remove(index);
                    })
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin

                Label {
                    text: model.label || qsTr("No label")
                    color: {
                        if (model.color === "green") return "#2ecc71";
                        if (model.color === "orange") return "#e67e22";
                        if (model.color === "red") return "#e74c3c";
                        if (model.color === "blue") return "#3498db";
                        return Theme.primaryColor;
                    }
                }
                Label {
                    text: {
                        var min = (model.minValue !== null && model.minValue !== undefined && model.minValue !== 0) ? "> " + model.minValue : "";
                        var max = (model.maxValue !== null && model.maxValue !== undefined && model.maxValue !== 0) ? "< " + model.maxValue : "";
                        if (min && max) return min + " and " + max;
                        if (min) return min;
                        if (max) return max;
                        return "—";
                    }
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No constraints defined")
            hintText: qsTr("Pull down to add a constraint")
        }

        VerticalScrollDecorator {}
    }

    ListModel { id: listModel }

    onStatusChanged: {
        if (status === PageStatus.Active) refresh();
    }

    Component.onCompleted: refresh()
}
