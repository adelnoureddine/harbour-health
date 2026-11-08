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

    property int rangeDays: 30
    property var chartSeries: []
    property var chartBands: []
    property var chartStats: null

    // day -> total, built once per refresh so section headers are a hash lookup.
    property var dayTotals: ({})

    // The top of the page: the latest reading (today's total for water and
    // calories), how it moved over the chart's range, and its reference band.
    property string profileName: ""
    property var latestValue: null
    property string latestTimestamp: ""
    property real todayTotal: 0
    property var goal: null
    property string changeText: ""
    property string bandLabel: ""
    property color bandColor: "transparent"
    // The day "Today" refers to: the 04:00-border day for daily totals.
    property var currentDay: new Date()

    readonly property int decimals: Utils.metricDecimals(metricName)
    // Unit with its leading space, or nothing for a unitless metric.
    readonly property string unitSuffix: metricUnit ? " " + metricUnit : ""
    // Set once the range has been chosen, by the first refresh or by the user.
    property bool rangeSettled: false
    // What the page last loaded (see DataManager.dataKey). Coming back from a cancelled
    // dialog, a chart or the reference ranges used to reload the whole history.
    property string loadedFrom: ""

    // The list holds every entry regardless of the chart range. With none at all the
    // chart, range tabs and stats are hidden, so the placeholder has the page to itself
    // instead of being drawn over them. Until the first refresh the page assumes there
    // is data, so the common case does not collapse and re-expand while being pushed.
    property bool loaded: false
    readonly property bool hasData: !loaded || listModel.count > 0

    // Long windows are averaged per day so the canvas never plots thousands of points.
    function seriesMode() {
        if (page.grouped) {
            return DataManager.SERIES_DAILY_SUM;
        }
        return (rangeDays === 0 || rangeDays > 90) ? DataManager.SERIES_DAILY_AVG
                                                   : DataManager.SERIES_RAW;
    }


    function refreshChart() {
        if (profileId < 0) {
            return;
        }
        var mode = seriesMode();
        var since = DataManager.sinceForDays(rangeDays, mode !== DataManager.SERIES_RAW);
        var points = DataManager.getSeries(profileId, metricName, since, mode);
        chartSeries = [{
            points: points,
            color: Theme.highlightColor,
            label: Utils.metricDisplayName(metricName)
        }];
        // "−0.8 kg since 9 Oct" over the chart's range. It only means something for
        // single readings, not for daily totals.
        changeText = page.grouped ? "" : Utils.changeSinceText(points, page.metricUnit, page.decimals);
        chartStats = DataManager.getSeriesStats(profileId, metricName, since, mode);
        chartBands = DataManager.getConstraintsForMetric(metricName);
    }

    function refreshHero() {
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        currentDay = page.grouped ? DataManager.dayStart() : new Date();
        if (page.grouped) {
            var total = DataManager.getTodayTotal(profileId, metricName);
            todayTotal = total === null ? 0 : total;
            goal = DataManager.getGoal(profileId, metricName);
            bandLabel = "";
            return;
        }
        var log = DataManager.getLatestLog(profileId, metricName);
        latestValue = log ? log.value : null;
        latestTimestamp = log ? log.timestamp : "";
        var band = Utils.bandFor(log ? DataManager.matchConstraint(metricName, log.value) : null);
        bandLabel = band.label;
        bandColor = band.color;
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
        dayTotals = DataManager.addLogsToModel(profileId, metricName, listModel, page.grouped);
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
                                        : Utils.formatValue(page.latestValue)
                unit: page.metricUnit
                detailText: page.grouped
                            ? qsTr("Today") + (page.goal !== null
                                               //: Daily goal under today's total, e.g. "Goal 2 L"
                                               ? " · " + qsTr("Goal %1").arg(Utils.formatValue(page.goal) + page.unitSuffix)
                                               : "")
                            : [page.changeText, Utils.measuredWhen(page.latestTimestamp)]
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
                unit: page.metricUnit
                decimals: page.decimals
                emptyText: qsTr("No data in this period")
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
                unit: page.metricUnit
                decimals: page.decimals
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
                                     + Utils.formatValue(page.dayTotals[section]) + page.unitSuffix
                                   : Utils.dayTitle(section)
            }
        }

        delegate: ListItem {
            id: listItem
            contentHeight: noteLabel.visible
                           ? Math.max(Theme.itemSizeMedium, entryColumn.height + 2 * Theme.paddingMedium)
                           : Theme.itemSizeSmall

            function remove() {
                listItem.remorseDelete(function() {
                    DataManager.deleteLog(model.id);
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
                    text: Utils.formatValue(model.value) + page.unitSuffix
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
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
