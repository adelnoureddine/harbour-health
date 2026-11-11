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
    // The stored unit (Metrics.unit), passed on to the dialogs. What the page shows is
    // in shownUnit, the unit chosen in Units: every value below is converted with
    // DataManager.toDisplay() right before it is shown, never when it is read.
    property string metricUnit

    property int rangeDays: 30
    property var chartSeries: []
    property var chartBands: []
    property var chartStats: null
    // The period the chart spans (ms), null for "All"; and the line to reach on it.
    property var rangeStart: null
    property var rangeEnd: null
    property var chartGoal: null
    property string chartGoalText: ""

    // day -> total, built once per refresh so section headers are a hash lookup.
    property var dayTotals: ({})

    // The top of the page: the latest reading (today's total for water and
    // calories), how it moved over the chart's range, and its reference band.
    property string profileName: ""
    property var latestValue: null
    property string latestTimestamp: ""
    property real todayTotal: 0
    // The daily goal (daily totals) or the target (weight, waist), as shown; null
    // without one or when it is switched off.
    property var goal: null
    property string changeText: ""
    property string bandLabel: ""
    property color bandColor: "transparent"
    // The day "Today" refers to: the 04:00-border day for daily totals.
    property var currentDay: new Date()

    readonly property bool hasTarget: !grouped && DataManager.hasTarget(metricName)
    property string shownUnit: metricUnit
    // Decimals of statistics and the chart, and of a reading as it was typed.
    property int decimals: Utils.metricDecimals(metricName)
    property int readingDecimals: 2
    // Unit with its leading space, or nothing for a unitless metric.
    readonly property string unitSuffix: shownUnit ? " " + shownUnit : ""
    // Set once the range has been chosen, by the first refresh or by the user.
    property bool rangeSettled: false
    // What the page last loaded (see DataManager.dataKey). Coming back from a cancelled
    // dialog, a chart or the reference ranges used to reload the whole history.
    property string loadedFrom: ""

    // The list holds the entries regardless of the chart range. With none at all the
    // chart, range tabs and stats are hidden, so the placeholder has the page to itself
    // instead of being drawn over them. Until the first refresh the page assumes there
    // is data, so the common case does not collapse and re-expand while being pushed.
    property bool loaded: false
    readonly property bool hasData: !loaded || listModel.count > 0

    /*
     * The list shows the newest `listLimit` entries, and more on request. It used to
     * hold the whole history -- years of glasses of water -- and was rebuilt in full
     * after every write.
     */
    readonly property int listStep: 200
    property int listLimit: listStep
    property int totalEntries: 0

    // How long one bar of a daily total is: "day", "week" or "month" (see refreshChart).
    property string bucket: "day"

    /*
     * Daily totals are bars. Up to three months that is a bar a day; a year is a bar a
     * week; "All" depends on how far back the history goes, so a few weeks of water are
     * still days and five years are months -- never more than about a hundred bars.
     */
    function bucketFor() {
        if (!page.grouped || (rangeDays > 0 && rangeDays <= 90)) {
            return "day";
        }
        if (rangeDays > 0) {
            return "week";
        }
        var first = DataManager.getFirstLogTimestamp(profileId, metricName);
        var days = first ? Utils.daysBetween(first, new Date()) : 0;
        return days <= 90 ? "day" : (days <= 730 ? "week" : "month");
    }

    // Long windows are averaged per day so the canvas never plots thousands of points.
    function seriesMode() {
        if (page.grouped) {
            return page.bucket === "week" ? DataManager.SERIES_WEEKLY
                 : page.bucket === "month" ? DataManager.SERIES_MONTHLY
                 : DataManager.SERIES_DAILY_SUM;
        }
        return (rangeDays === 0 || rangeDays > 90) ? DataManager.SERIES_DAILY_AVG
                                                   : DataManager.SERIES_RAW;
    }

    function withUnit(value, valueDecimals) {
        return Utils.formatValue(value, valueDecimals) + unitSuffix;
    }

    function refreshChart() {
        if (profileId < 0) {
            return;
        }
        bucket = bucketFor();
        var mode = seriesMode();
        var since = DataManager.sinceForDays(rangeDays, mode !== DataManager.SERIES_RAW);
        var points = DataManager.displayPoints(metricName, DataManager.getSeries(profileId, metricName, since, mode));
        // The chart spans the period asked for, not just the readings in it. Bars sit
        // on calendar days, so their period starts and ends at midnight.
        if (since === null) {
            rangeStart = null;
            rangeEnd = null;
        } else if (page.grouped) {
            var lastDay = DataManager.dayStart();
            rangeStart = DataManager.timestampToMs(since.substring(0, 10));
            rangeEnd = new Date(lastDay.getFullYear(), lastDay.getMonth(), lastDay.getDate() + 1).getTime();
        } else {
            rangeStart = DataManager.timestampToMs(since);
            rangeEnd = Date.now();
        }
        chartSeries = [{
            points: points,
            color: Theme.highlightColor,
            label: Utils.metricDisplayName(metricName)
        }];
        // "−0.8 kg since 9 Oct" over the chart's range. It only means something for
        // single readings, not for daily totals.
        changeText = page.grouped ? "" : Utils.changeSinceText(points, page.shownUnit, page.decimals);
        // Statistics of a daily total stay per day whatever the bars are: the average
        // day, the best and the lowest. Those of readings are of the readings
        // themselves on every range: past three months the chart plots daily averages,
        // and "Max" was the highest daily average, not the highest reading.
        chartStats = DataManager.displayStats(metricName, DataManager.getSeriesStats(
                                                  profileId, metricName, since,
                                                  page.grouped ? DataManager.SERIES_DAILY_SUM : DataManager.SERIES_RAW));
        chartBands = DataManager.displayBands(metricName, DataManager.getConstraintsForMetric(metricName));
    }

    function refreshHero() {
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        shownUnit = DataManager.displayUnit(metricName, metricUnit);
        decimals = DataManager.displayDecimals(metricName, Utils.metricDecimals(metricName));
        readingDecimals = DataManager.displayDecimals(metricName, 2);
        currentDay = page.grouped ? DataManager.dayStart() : new Date();

        var stored = DataManager.getActiveGoal(profileId, metricName);
        goal = stored === null ? null : DataManager.toDisplay(metricName, stored);
        chartGoal = page.grouped || page.hasTarget ? goal : null;
        chartGoalText = chartGoal === null ? ""
                      //: On the chart, next to the line of the daily goal, e.g. "Goal 2 L"
                      : page.grouped ? qsTr("Goal %1").arg(withUnit(goal, decimals))
                      //: On the chart, next to the line of the target, e.g. "Target 70 kg"
                      : qsTr("Target %1").arg(withUnit(goal, readingDecimals));

        if (page.grouped) {
            var total = DataManager.getTodayTotal(profileId, metricName);
            todayTotal = DataManager.toDisplay(metricName, total === null ? 0 : total);
            bandLabel = "";
            return;
        }
        var log = DataManager.getLatestLog(profileId, metricName);
        latestValue = log ? DataManager.toDisplay(metricName, log.value) : null;
        latestTimestamp = log ? log.timestamp : "";
        // The band is matched on the stored value: the ranges are stored ones too.
        var band = Utils.bandFor(log ? DataManager.matchConstraint(metricName, log.value) : null);
        bandLabel = band.label;
        bandColor = band.color;
    }

    // "1.3 kg from target", or "On target" within what the value shows.
    function targetText() {
        if (!page.hasTarget || page.goal === null || page.latestValue === null) {
            return "";
        }
        var distance = Math.abs(page.latestValue - page.goal);
        if (Utils.formatValue(distance, readingDecimals) === Utils.formatValue(0, readingDecimals)) {
            //: Under the latest reading when it matches the target
            return qsTr("On target");
        }
        //: Under the latest reading: how far it is from the target, e.g. "1.3 kg from target"
        return qsTr("%1 from target").arg(withUnit(distance, readingDecimals));
    }

    function refresh() {
        var key = DataManager.dataKey();
        refreshHero();
        // Rebuilding the list puts the view back at the top. After editing or deleting
        // an entry further down, the user was thrown back there.
        var keepY = loaded ? listView.contentY : null;
        listModel.clear();
        // The totals come back with the rows. They used to be collected by reading
        // every row back out of the model, the slowest part of opening the page.
        dayTotals = DataManager.addLogsToModel(profileId, metricName, listModel, page.grouped, listLimit);
        totalEntries = listModel.count < listLimit ? listModel.count
                                                   : DataManager.countLogs(profileId, metricName);
        listView.forceLayout();
        if (keepY !== null) {
            listView.contentY = keepY;
            listView.returnToBounds();
        } else {
            scrollToTop.restart();
        }
        loaded = true;
        refreshChart();
        // Someone whose last reading is older than the default month used to get
        // "No data in this period" above a full list. Show everything instead.
        if (!rangeSettled) {
            rangeSettled = true;
            if (listModel.count > 0 && chartStats !== null && chartStats.count === 0) {
                rangeDays = 0;
            }
        }
        loadedFrom = key;
    }

    // Also called by the window when the app comes back or the day turns.
    function reloadIfStale() {
        if (DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }

    function openGoal() {
        pageStack.animatorPush(Qt.resolvedUrl("setGoal.qml"), {
            profileId: page.profileId,
            metricName: page.metricName,
            metricUnit: page.metricUnit
        });
    }

    onRangeDaysChanged: refreshChart()

    SilicaListView {
        id: listView
        anchors.fill: parent
        onMovementStarted: page.holdTop = false

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium
            onHeightChanged: {
                if (page.holdTop) {
                    scrollToTop.restart();
                }
            }

            PageHeader {
                title: Utils.metricDisplayName(page.metricName)
                description: page.profileName
            }

            HistoryHero {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: page.hasData
                valueText: page.grouped ? Utils.formatValue(page.todayTotal, page.decimals)
                                        : Utils.formatValue(page.latestValue, page.readingDecimals)
                unit: page.shownUnit
                detailText: page.grouped
                            ? qsTr("Today") + (page.goal !== null
                                               //: Daily goal under today's total, e.g. "Goal 2 L"
                                               ? " · " + qsTr("Goal %1").arg(page.withUnit(page.goal, page.decimals))
                                               : "")
                            : [page.targetText(), page.changeText, Utils.measuredWhen(page.latestTimestamp, appWindow.today)]
                                  .filter(function (part) { return part !== ""; }).join(" · ")
                bandLabel: page.bandLabel
                bandColor: page.bandColor
            }

            ChartCard {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                visible: page.hasData
                series: page.chartSeries
                bands: page.chartBands
                unit: page.shownUnit
                decimals: page.decimals
                emptyText: qsTr("No data in this period")
                // Daily totals add up, so they are bars; readings stay a line.
                bars: page.grouped
                bucket: page.bucket
                averageValue: page.grouped && page.chartStats ? page.chartStats.avg : null
                goalValue: page.chartGoal
                goalText: page.chartGoalText
                rangeStart: page.rangeStart
                rangeEnd: page.rangeEnd
            }

            ChartRangeSelector {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                visible: page.hasData
                days: page.rangeDays
                onDaysChanged: page.rangeDays = days
            }

            // No visible override: ChartStats already hides itself without data, and
            // setting visible here would replace that binding.
            ChartStats {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                stats: page.chartStats
                unit: page.shownUnit
                decimals: page.decimals
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        // More of the history, a step at a time, once the newest entries are not all.
        footer: Item {
            width: listView.width
            height: olderButton.visible ? olderButton.height + 2 * Theme.paddingLarge : 0

            Button {
                id: olderButton
                anchors.centerIn: parent
                visible: page.loaded && listModel.count < page.totalEntries
                //: Button under a history list that shows only the newest entries
                text: qsTr("Show older entries")
                onClicked: {
                    page.listLimit += page.listStep;
                    page.refresh();
                }
            }
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
                visible: page.grouped || page.hasTarget
                //: Menu item: set the value a measurement such as weight should reach
                text: page.grouped ? qsTr("Daily goal") : qsTr("Target")
                onClicked: page.openGoal()
            }
            MenuItem {
                text: qsTr("Add entry")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: page.profileId,
                    metricName: page.metricName,
                    metricUnit: page.metricUnit,
                    lockMetric: true
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
                // "Today", "Yesterday", then the weekday and date; daily totals add the
                // day's sum. The total is computed by SQLite, not by re-scanning the model.
                text: page.grouped ? Utils.dayTitle(section, page.currentDay) + " · "
                                     + page.withUnit(DataManager.toDisplay(page.metricName, page.dayTotals[section]),
                                                     page.readingDecimals)
                                   : Utils.dayTitle(section)
            }
        }

        delegate: ListItem {
            id: listItem
            contentHeight: noteLabel.visible
                           ? Math.max(Theme.itemSizeMedium, entryColumn.height + 2 * Theme.paddingMedium)
                           : Theme.itemSizeSmall

            function remove() {
                // The id is read now: a refresh during the countdown rebuilds the rows,
                // and this one's model with them.
                var id = model.id;
                listItem.remorseDelete(function() {
                    DataManager.deleteLog(id);
                    page.refresh();
                })
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                            profileId: page.profileId,
                            metricName: page.metricName,
                            metricUnit: page.metricUnit,
                            lockMetric: true,
                            logId: model.id
                        })
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: listItem.remove()
                    }
                }
            }

            Column {
                id: entryColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin - timeLabel.width - Theme.paddingMedium
                spacing: 0

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: page.withUnit(DataManager.toDisplay(page.metricName, model.value), page.readingDecimals)
                    color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }

                Label {
                    id: noteLabel
                    width: parent.width
                    text: model.note ? model.note : ""
                    visible: text !== ""
                    // Two lines before eliding: one faded line cut most notes short.
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Elide
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            Label {
                id: timeLabel
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                // The day is in the section header above.
                text: Utils.formatTime(model.timestamp)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: listItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
        }

        ViewPlaceholder {
            enabled: !page.hasData
            text: qsTr("No data points recorded")
            hintText: qsTr("Pull down to add the first entry")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    /*
     * A page opens at its top, header included. The header keeps growing for a moment
     * after the list loads (latest reading, change line, stats), and the list view keeps
     * its rows where they were, so the header ended up partly off-screen. Until the user
     * scrolls, every change of the header's height puts the view back at the top.
     */
    property bool holdTop: true

    Timer {
        id: scrollToTop
        interval: 50
        onTriggered: {
            listView.forceLayout();
            listView.positionViewAtBeginning();
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            reloadIfStale();
        }
    }
}

// vim:et:ts=4:sw=4
