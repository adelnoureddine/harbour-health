import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property string metricName: ""
    property string metricUnit: ""

    function refresh() {
        listModel.clear();
        var constraints = DataManager.getConstraintsForMetric(metricName);
        constraints.forEach(function(constraint) {
            listModel.append(constraint);
        });
    }

    function rangeText(minValue, maxValue) {
        var hasMin = minValue !== null && minValue !== undefined;
        var hasMax = maxValue !== null && maxValue !== undefined;
        var unit = page.metricUnit ? " " + page.metricUnit : "";
        // A threshold of exactly 0 is a real bound; it used to be treated as absent.
        if (hasMin && hasMax) {
            return qsTr("%1 to %2").arg(Utils.formatValue(minValue)).arg(Utils.formatValue(maxValue)) + unit;
        }
        if (hasMin) {
            return qsTr("%1 and above").arg(Utils.formatValue(minValue)) + unit;
        }
        if (hasMax) {
            return qsTr("below %1").arg(Utils.formatValue(maxValue)) + unit;
        }
        return "";
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Reference ranges")
                description: Utils.metricDisplayName(page.metricName)
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("These bands colour your readings and shade the chart behind them. They are general references, not medical advice — edit them to whatever your own targets are.")
            }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add range")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addConstraint.qml"), {
                    metricName: page.metricName,
                    metricUnit: page.metricUnit
                })
            }
        }

        model: listModel

        delegate: ListItem {
            id: constraintItem
            contentHeight: Theme.itemSizeMedium

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("addConstraint.qml"), {
                        metricName: page.metricName,
                        metricUnit: page.metricUnit,
                        constraintId: model.id,
                        labelText: model.label ? model.label : "",
                        minValue: model.minValue,
                        maxValue: model.maxValue,
                        colorName: model.color
                    })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: constraintItem.remorseDelete(function() {
                        DataManager.deleteConstraint(model.id);
                        listModel.remove(index);
                    })
                }
            }

            Rectangle {
                id: swatch
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: Theme.paddingSmall
                height: parent.height - Theme.paddingLarge
                radius: width / 2
                color: Utils.constraintColor(model.color) !== "" ? Utils.constraintColor(model.color)
                                                                 : Theme.secondaryColor
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: swatch.right
                anchors.leftMargin: Theme.paddingMedium
                width: parent.width - swatch.width - Theme.horizontalPageMargin * 2 - Theme.paddingMedium

                Label {
                    width: parent.width
                    text: model.label ? model.label : qsTr("Unnamed range")
                    truncationMode: TruncationMode.Fade
                    color: constraintItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: page.rangeText(model.minValue, model.maxValue)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No reference ranges")
            hintText: qsTr("Pull down to add one")
        }

        VerticalScrollDecorator {}
    }

    ListModel { id: listModel }

    onStatusChanged: {
        if (status === PageStatus.Active) refresh();
    }
}

// vim:et:ts=4:sw=4
