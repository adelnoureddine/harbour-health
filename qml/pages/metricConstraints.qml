import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    // A metric's name, or a module's for the derived values (BMI, WHtR), which have no
    // unit. metricUnit is the stored unit: the bounds are kept in it and shown, like
    // every value, in the unit chosen in Units.
    property string metricName: ""
    property string metricUnit: ""

    // What the page last loaded (see DataManager.dataKey): coming back from a
    // cancelled dialog no longer rebuilds the list.
    property string loadedFrom: ""

    /*
     * A ListModel cannot hold null: an open end came back as 0, so "Below 50" read
     * "0 to 50" and editing that band saved a minimum of 0. Each end carries a flag.
     */
    function refresh() {
        var key = DataManager.dataKey();
        listModel.clear();
        var rows = DataManager.getConstraintsForMetric(metricName).map(function (c) {
            var hasMin = c.minValue !== null && c.minValue !== undefined;
            var hasMax = c.maxValue !== null && c.maxValue !== undefined;
            return {
                id: c.id,
                label: c.label ? c.label : "",
                color: c.color ? c.color : "",
                hasMin: hasMin,
                minValue: hasMin ? c.minValue : 0,
                hasMax: hasMax,
                maxValue: hasMax ? c.maxValue : 0
            };
        });
        if (rows.length > 0) {
            listModel.append(rows);
        }
        loadedFrom = key;
    }

    function rangeText(minValue, maxValue) {
        var hasMin = minValue !== null && minValue !== undefined;
        var hasMax = maxValue !== null && maxValue !== undefined;
        var shownUnit = DataManager.displayUnit(page.metricName, page.metricUnit);
        var unit = shownUnit ? " " + shownUnit : "";
        var decimals = DataManager.displayDecimals(page.metricName, 2);
        function shown(value) {
            return Utils.formatValue(DataManager.toDisplay(page.metricName, value), decimals);
        }
        // A threshold of exactly 0 is a real bound; it used to be treated as absent.
        if (hasMin && hasMax) {
            //: Reference range from a minimum (%1) to a maximum (%2) value
            return qsTr("%1 to %2").arg(shown(minValue)).arg(shown(maxValue)) + unit;
        }
        if (hasMin) {
            //: Reference range with only a minimum value (%1)
            return qsTr("%1 and above").arg(shown(minValue)) + unit;
        }
        if (hasMax) {
            //: Reference range with only a maximum value (%1)
            return qsTr("Below %1").arg(shown(maxValue)) + unit;
        }
        return "";
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        // Room between the card rows.
        spacing: Theme.paddingMedium

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Reference ranges")
                description: Utils.metricDisplayName(page.metricName)
            }

            Card {
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                    text: qsTr("These bands colour your readings and shade the chart behind them. They are general references, not medical advice — edit them to whatever your own targets are.")
                }
            }

            Item { width: 1; height: Theme.paddingSmall }
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
            contentHeight: Math.max(Theme.itemSizeMedium, textColumn.height + 2 * Theme.paddingMedium)
            // The card below shows the press instead of a full-width block.
            highlightedColor: "transparent"

            // On the row, not in the menu: the lazy menu is destroyed when it closes,
            // seconds before the remorse runs, and its callback lost `model` with it.
            function remove() {
                var constraintId = model.id;
                constraintItem.remorseDelete(function() {
                    DataManager.deleteConstraint(constraintId);
                    listModel.remove(index);
                })
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("addConstraint.qml"), {
                            metricName: page.metricName,
                            metricUnit: page.metricUnit,
                            constraintId: model.id,
                            labelText: model.label,
                            minValue: model.hasMin ? model.minValue : null,
                            maxValue: model.hasMax ? model.maxValue : null,
                            colorName: model.color
                        })
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: constraintItem.remove()
                    }
                }
            }

            CardBackground {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: parent.height
                highlighted: constraintItem.highlighted
            }

            // The band's colour, as the dot of its pill on the history page.
            Rectangle {
                id: swatch
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin + Theme.paddingLarge
                width: Theme.iconSizeSmall
                height: width
                radius: width / 2
                color: Utils.constraintColor(model.color) !== "" ? Utils.constraintColor(model.color)
                                                                 : Theme.secondaryColor
            }

            Column {
                id: textColumn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: swatch.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin + Theme.paddingLarge

                Label {
                    width: parent.width
                    text: model.label ? Utils.constraintLabelDisplayName(model.label) : qsTr("Unnamed range")
                    truncationMode: TruncationMode.Fade
                    color: constraintItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: page.rangeText(model.hasMin ? model.minValue : null,
                                         model.hasMax ? model.maxValue : null)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: constraintItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            // Below the explanation card rather than over it.
            verticalOffset: listView.headerItem ? listView.headerItem.height : 0
            text: qsTr("No reference ranges")
            hintText: qsTr("Pull down to add one")
        }

        VerticalScrollDecorator {}
    }

    ListModel { id: listModel }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
