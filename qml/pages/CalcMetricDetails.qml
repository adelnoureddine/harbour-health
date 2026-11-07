import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * History for a derived metric -- one computed from other measurements rather than
 * logged directly: BMI (weight and height) and the waist-to-height ratio (waist and
 * height). The BMI card was previously inert: tapping it did nothing, so neither its
 * history nor its reference bands were reachable.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string calculate: DataManager.CALC_BMI
    property string title: qsTr("BMI")
    property string metricUnit: ""
    property var invalidateSignal

    property int rangeDays: 365
    property var chartSeries: []
    property var chartBands: []
    property var chartStats: null
    property var currentValue: null
    property string currentLabel: ""
    property string currentColor: ""

    // The history list follows the chart range, so it cannot tell "nothing in this
    // period" from "nothing at all"; the current value can. With nothing to calculate
    // the chart, range tabs and stats are hidden so the placeholder is not drawn over
    // them. Until the first refresh the page assumes there is data, so the common case
    // does not collapse and re-expand while it is being pushed.
    property bool loaded: false
    readonly property bool hasData: !loaded || currentValue !== null

    // The untranslated module name reference bands are stored under, passed in by the
    // dashboard card. The fallback only matters if the page is opened from elsewhere.
    property string constraintKey: ""
    readonly property string bandKey: constraintKey !== "" ? constraintKey
                                    : (isWHtR ? DataManager.MODULE_WHTR : DataManager.MODULE_BMI)

    // What differs between the derived metrics. Both are computed from height and one
    // other measurement, logged from this page's pull-down menu.
    readonly property bool isBMI: calculate === DataManager.CALC_BMI
    readonly property bool isWHtR: calculate === DataManager.CALC_WHTR
    readonly property string inputMetric: isWHtR ? DataManager.METRIC_WAIST : DataManager.METRIC_WEIGHT
    // A ratio around 0.5 is meaningless at one decimal.
    readonly property int decimals: isWHtR ? 2 : 1

    function refresh() {
        if (profileId < 0) {
            return;
        }

        var since = DataManager.sinceForDays(rangeDays, false);
        var points = isWHtR ? DataManager.getWHtRSeries(profileId, since)
                   : isBMI ? DataManager.getBMISeries(profileId, since)
                   : [];
        chartSeries = [{
            points: points,
            color: Theme.highlightColor,
            label: page.title
        }];
        // A derived metric has no table of its own, so its statistics come from the series.
        chartStats = DataManager.statsFromPoints(points);
        chartBands = DataManager.getConstraintsForMetric(bandKey);

        currentValue = DataManager.calculateMetrics(profileId, calculate);
        var match = DataManager.matchConstraint(bandKey, currentValue);
        currentLabel = match === null ? "" : Utils.constraintLabelDisplayName(match.label);
        currentColor = match === null ? "" : Utils.constraintColor(match.color);

        historyModel.clear();
        for (var i = points.length - 1; i >= 0; i--) {
            historyModel.append({ t: points[i].t, v: points[i].v });
        }
        loaded = true;
    }

    onRangeDaysChanged: refresh()

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.title
            }

            Column {
                width: parent.width
                spacing: 0
                visible: page.hasData

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: page.currentValue === null ? "—" : Utils.formatValue(page.currentValue, page.decimals)
                    font.pixelSize: Theme.fontSizeHuge
                    color: page.currentColor !== "" ? page.currentColor : Theme.primaryColor
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: page.currentLabel
                    visible: text !== ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: page.currentColor !== "" ? page.currentColor : Theme.secondaryColor
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                visible: (page.isBMI || page.isWHtR) && page.hasData
                text: page.isWHtR
                      ? qsTr("Calculated from your waist and the height recorded at the time. An estimate, not a diagnosis: a common rule of thumb is to keep your waist below half your height, and cut-offs vary with age and ethnicity.")
                      : page.currentValue === null
                        ? qsTr("Record a weight and a height to see your BMI.")
                        : qsTr("Calculated from your weight and the height recorded at the time.")
            }

            // Where to measure: readings taken at different spots are not comparable.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                visible: page.isWHtR && page.hasData
                text: Utils.metricHint(DataManager.METRIC_WAIST)
            }

            MetricChart {
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
                    metricName: page.bandKey,
                    metricUnit: page.metricUnit
                })
            }
            MenuItem {
                text: qsTr("Add height")
                visible: page.isBMI || page.isWHtR
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: page.profileId,
                    metricName: DataManager.METRIC_HEIGHT,
                    metricUnit: DataManager.getMetricUnit(DataManager.METRIC_HEIGHT),
                    lockMetric: true,
                    invalidateSignal: page.invalidateSignal
                })
            }
            MenuItem {
                text: page.isWHtR ? qsTr("Add waist") : qsTr("Add weight")
                visible: page.isBMI || page.isWHtR
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: page.profileId,
                    metricName: page.inputMetric,
                    metricUnit: DataManager.getMetricUnit(page.inputMetric),
                    lockMetric: true,
                    invalidateSignal: page.invalidateSignal
                })
            }
        }

        model: historyModel

        delegate: ListItem {
            contentHeight: Theme.itemSizeSmall

            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width / 2 - Theme.horizontalPageMargin
                truncationMode: TruncationMode.Fade
                text: Utils.formatValue(model.v, page.decimals)
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width / 2 - Theme.horizontalPageMargin
                horizontalAlignment: Text.AlignRight
                truncationMode: TruncationMode.Fade
                text: Qt.formatDate(new Date(model.t), Qt.DefaultLocaleShortDate)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
        }

        ViewPlaceholder {
            enabled: !page.hasData
            text: qsTr("Nothing to calculate yet")
            hintText: page.isWHtR ? qsTr("Pull down to record a height and a waist measurement")
                                  : qsTr("Pull down to record a height and a weight")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: historyModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) refresh();
    }
}

// vim:et:ts=4:sw=4
