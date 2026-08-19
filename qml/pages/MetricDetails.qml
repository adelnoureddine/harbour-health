import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property bool grouped: false
    property string metricName
    property string metricUnit
    property var invalidateSignal

    property int rangeDays: 30
    property var chartSeries: []
    property var chartBands: []
    property var chartStats: null

    // day -> total, built once per refresh so section headers are a hash lookup.
    property var dayTotals: ({})

    // Long windows are averaged per day so the canvas never plots thousands of points.
    function seriesMode() {
        if (page.grouped) {
            return DataManager.SERIES_DAILY_SUM;
        }
        return (rangeDays === 0 || rangeDays > 90) ? DataManager.SERIES_DAILY_AVG
                                                   : DataManager.SERIES_RAW;
    }

    function sinceTimestamp() {
        if (rangeDays === 0) {
            return null;
        }
        var from = new Date();
        from.setDate(from.getDate() - rangeDays);
        from.setHours(0, 0, 0, 0);
        return DataManager.toTimestamp(from);
    }

    function refreshChart() {
        if (profileId < 0) {
            return;
        }
        var since = sinceTimestamp();
        var mode = seriesMode();
        chartSeries = [{
            points: DataManager.getSeries(profileId, metricName, since, mode),
            color: Theme.highlightColor,
            label: Utils.metricDisplayName(metricName)
        }];
        chartStats = DataManager.getSeriesStats(profileId, metricName, since, mode);
        chartBands = DataManager.getConstraintsForMetric(metricName);
    }

    function refresh() {
        listModel.clear();
        DataManager.addLogsToModel(profileId, metricName, listModel, page.grouped);
        var totals = {};
        for (var i = 0; i < listModel.count; i++) {
            var item = listModel.get(i);
            if (item.day !== undefined) {
                totals[item.day] = item.dayTotal;
            }
        }
        dayTotals = totals;
        refreshChart();
    }

    function notifyChanged() {
        if (page.invalidateSignal) {
            page.invalidateSignal(page.metricName);
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
                title: Utils.metricDisplayName(page.metricName)
                description: page.metricUnit
            }

            MetricChart {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                series: page.chartSeries
                bands: page.chartBands
                unit: page.metricUnit
                emptyText: qsTr("No data in this period")
            }

            ChartRangeSelector {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                days: page.rangeDays
                onDaysChanged: page.rangeDays = days
            }

            ChartStats {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                stats: page.chartStats
                unit: page.metricUnit
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Reference ranges")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("metricConstraints.qml"), {
                    metricName: page.metricName,
                    metricUnit: page.metricUnit
                })
            }
            MenuItem {
                text: qsTr("Add Entry")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: page.profileId,
                    metricName: page.metricName,
                    metricUnit: page.metricUnit,
                    lockMetric: true,
                    invalidateSignal: page.invalidateSignal
                })
            }
        }

        model: listModel

        section {
            property: "day"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                width: ListView.view.width
                // The per-day total is computed by SQLite now. It used to re-scan the
                // whole model inside this binding, once per section, on every update.
                text: Utils.formatValue(page.dayTotals[section]) + " " + page.metricUnit
                      + " · " + Utils.formatDate(section)
            }
        }

        delegate: ListItem {
            id: listItem
            contentHeight: noteLabel.visible ? Theme.itemSizeMedium : Theme.itemSizeSmall

            function remove() {
                listItem.remorseDelete(function() {
                    DataManager.deleteLog(model.id);
                    page.refresh();
                    page.notifyChanged();
                })
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Edit")
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                        profileId: page.profileId,
                        metricName: page.metricName,
                        metricUnit: page.metricUnit,
                        lockMetric: true,
                        logId: model.id,
                        invalidateSignal: page.invalidateSignal
                    })
                }
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: listItem.remove()
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
                    text: Utils.formatValue(model.value) + " " + page.metricUnit
                    color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
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
                // Within a day section the date is already in the header.
                text: page.grouped ? Utils.formatTime(model.timestamp)
                                   : Utils.formatDateTime(model.timestamp)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
}

// vim:et:ts=4:sw=4
