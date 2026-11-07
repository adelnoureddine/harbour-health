import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metricName1
    property string metricName2
    property string metricUnit: "mmHg"
    property var invalidateSignal

    property int rangeDays: 30
    property var chartSeries: []
    property var chartBands: []

    // The list holds every reading regardless of the chart range. With none at all the
    // chart and range tabs are hidden, so the placeholder has the page to itself instead
    // of being drawn over them. Until the first refresh the page assumes there is data,
    // so the common case does not collapse and re-expand while it is being pushed.
    property bool loaded: false
    readonly property bool hasData: !loaded || listModel.count > 0
    // Set once the range has been chosen, by the first refresh or by the user.
    property bool rangeSettled: false

    function refreshChart() {
        if (profileId < 0) {
            return;
        }
        var mode = (rangeDays === 0 || rangeDays > 90) ? DataManager.SERIES_DAILY_AVG
                                                       : DataManager.SERIES_RAW;
        var since = DataManager.sinceForDays(rangeDays, mode !== DataManager.SERIES_RAW);
        chartSeries = [
            {
                points: DataManager.getSeries(profileId, metricName1, since, mode),
                color: Theme.highlightColor,
                label: Utils.metricDisplayName(metricName1)
            },
            {
                points: DataManager.getSeries(profileId, metricName2, since, mode),
                color: Theme.secondaryHighlightColor,
                label: Utils.metricDisplayName(metricName2)
            }
        ];
        // Systolic and diastolic share one axis, so both sets of bands are drawn.
        chartBands = DataManager.getConstraintsForMetric(metricName1)
                .concat(DataManager.getConstraintsForMetric(metricName2));
    }

    /*
     * Systolic and diastolic are stored as two rows sharing a timestamp. Both arrive
     * ordered, so one merge pass pairs them; anything unmatched is still shown, with
     * the missing half blank.
     */
    function refresh() {
        listModel.clear();

        var systolic = DataManager.getLogsAscending(profileId, metricName1, null);
        var diastolic = DataManager.getLogsAscending(profileId, metricName2, null);
        var rows = [];
        var i = 0;
        var j = 0;

        function minuteOf(log) {
            return String(log.timestamp).substring(0, 16);
        }

        while (i < systolic.length || j < diastolic.length) {
            if (i < systolic.length && j < diastolic.length) {
                var a = minuteOf(systolic[i]);
                var b = minuteOf(diastolic[j]);
                if (a === b) {
                    rows.push({ id1: systolic[i].id, id2: diastolic[j].id,
                                value1: systolic[i].value, value2: diastolic[j].value,
                                timestamp: systolic[i].timestamp,
                                note: systolic[i].note || diastolic[j].note || "" });
                    i++;
                    j++;
                } else if (a < b) {
                    rows.push({ id1: systolic[i].id, id2: -1, value1: systolic[i].value,
                                value2: "", timestamp: systolic[i].timestamp,
                                note: systolic[i].note || "" });
                    i++;
                } else {
                    rows.push({ id1: -1, id2: diastolic[j].id, value1: "",
                                value2: diastolic[j].value, timestamp: diastolic[j].timestamp,
                                note: diastolic[j].note || "" });
                    j++;
                }
            } else if (i < systolic.length) {
                rows.push({ id1: systolic[i].id, id2: -1, value1: systolic[i].value,
                            value2: "", timestamp: systolic[i].timestamp,
                            note: systolic[i].note || "" });
                i++;
            } else {
                rows.push({ id1: -1, id2: diastolic[j].id, value1: "",
                            value2: diastolic[j].value, timestamp: diastolic[j].timestamp,
                            note: diastolic[j].note || "" });
                j++;
            }
        }

        // Newest first, and with the day the section headers group by.
        for (var k = rows.length - 1; k >= 0; k--) {
            rows[k].day = String(rows[k].timestamp).split("T")[0];
            listModel.append(rows[k]);
        }

        loaded = true;
        refreshChart();
        // Readings older than the default month: show everything rather than an empty
        // chart above a full list.
        if (!rangeSettled) {
            rangeSettled = true;
            if (listModel.count > 0 && chartSeries[0].points.length === 0
                    && chartSeries[1].points.length === 0) {
                rangeDays = 0;
            }
        }
    }

    function notifyChanged() {
        if (page.invalidateSignal) {
            page.invalidateSignal(page.metricName1);
            page.invalidateSignal(page.metricName2);
        }
    }

    onRangeDaysChanged: refreshChart()

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Blood pressure")
                description: page.metricUnit
            }

            MetricChart {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                visible: page.hasData
                series: page.chartSeries
                bands: page.chartBands
                unit: page.metricUnit
                decimals: 0
                emptyText: qsTr("No data in this period")
            }

            ChartRangeSelector {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                visible: page.hasData
                days: page.rangeDays
                onDaysChanged: page.rangeDays = days
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        PullDownMenu {
            // Systolic and diastolic have separate bands; both used to be drawn on the
            // chart while only the systolic set could be opened for editing.
            MenuItem {
                text: qsTr("Systolic reference ranges")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("metricConstraints.qml"), {
                    metricName: page.metricName1,
                    metricUnit: page.metricUnit
                })
            }
            MenuItem {
                text: qsTr("Diastolic reference ranges")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("metricConstraints.qml"), {
                    metricName: page.metricName2,
                    metricUnit: page.metricUnit
                })
            }
            MenuItem {
                text: qsTr("Add entry")
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
            // No width override: SectionHeader already spans the view minus both page
            // margins. Setting the full view width pushed the right-aligned text one
            // margin off-screen and clipped the date.
            delegate: SectionHeader {
                text: Utils.formatDate(section)
            }
        }

        delegate: ListItem {
            id: listItem
            contentHeight: noteLabel.visible ? Theme.itemSizeMedium : Theme.itemSizeSmall

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    // Editing only makes sense for a complete pair.
                    enabled: model.id1 >= 0 && model.id2 >= 0
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMultiMetric.qml"), {
                        profileId: page.profileId,
                        metricName1: page.metricName1,
                        metricName2: page.metricName2,
                        metricUnit: page.metricUnit,
                        logId1: model.id1,
                        logId2: model.id2,
                        invalidateSignal: page.invalidateSignal
                    })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: {
                        listItem.remorseDelete(function() {
                            if (model.id1 >= 0) DataManager.deleteLog(model.id1);
                            if (model.id2 >= 0) DataManager.deleteLog(model.id2);
                            page.refresh();
                            page.notifyChanged();
                        })
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin - timeLabel.width - Theme.paddingMedium
                spacing: 0

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: (model.value1 === "" ? "—" : Utils.formatValue(model.value1)) + " / "
                          + (model.value2 === "" ? "—" : Utils.formatValue(model.value2))
                          + " " + page.metricUnit
                    color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeMedium
                }

                Label {
                    id: noteLabel
                    width: parent.width
                    text: model.note ? model.note : ""
                    visible: text !== ""
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            Label {
                id: timeLabel
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: Utils.formatTime(model.timestamp)
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }

        ViewPlaceholder {
            enabled: !page.hasData
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
}

// vim:et:ts=4:sw=4
