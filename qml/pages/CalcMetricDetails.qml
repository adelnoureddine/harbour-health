import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * History for a derived metric -- one computed from other measurements rather than
 * logged directly. Currently that means BMI, whose card was previously inert: tapping
 * it did nothing, so neither its history nor its reference bands were reachable.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string calculate: "bmi"
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

    // The name reference bands are stored under. Modules use the display name here.
    readonly property string constraintKey: calculate === "bmi" ? "BMI" : calculate

    function sinceTimestamp() {
        if (rangeDays === 0) {
            return null;
        }
        var from = new Date();
        from.setDate(from.getDate() - rangeDays);
        from.setHours(0, 0, 0, 0);
        return DataManager.toTimestamp(from);
    }

    function refresh() {
        if (profileId < 0) {
            return;
        }

        var points = calculate === "bmi" ? DataManager.getBMISeries(profileId, sinceTimestamp()) : [];
        chartSeries = [{
            points: points,
            color: Theme.highlightColor,
            label: page.title
        }];
        // BMI has no table of its own, so its statistics come from the series.
        chartStats = DataManager.statsFromPoints(points);
        chartBands = DataManager.getConstraintsForMetric(constraintKey);

        currentValue = DataManager.calculateMetrics(profileId, calculate);
        var match = DataManager.matchConstraint(constraintKey, currentValue);
        currentLabel = match === null ? "" : match.label;
        currentColor = match === null ? "" : Utils.constraintColor(match.color);

        historyModel.clear();
        for (var i = points.length - 1; i >= 0; i--) {
            historyModel.append({ t: points[i].t, v: points[i].v });
        }
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

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: page.currentValue === null ? "—" : Utils.formatValue(page.currentValue, 1)
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
                visible: page.calculate === "bmi"
                text: page.currentValue === null
                      ? qsTr("Record a weight and a height to see your BMI.")
                      : qsTr("Calculated from your weight and the height recorded at the time.")
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
                    metricName: page.constraintKey,
                    metricUnit: page.metricUnit
                })
            }
            MenuItem {
                text: qsTr("Add height")
                visible: page.calculate === "bmi"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: page.profileId,
                    metricName: DataManager.METRIC_HEIGHT,
                    metricUnit: DataManager.getMetricUnit(DataManager.METRIC_HEIGHT),
                    lockMetric: true,
                    invalidateSignal: page.invalidateSignal
                })
            }
            MenuItem {
                text: qsTr("Add weight")
                visible: page.calculate === "bmi"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                    profileId: page.profileId,
                    metricName: DataManager.METRIC_WEIGHT,
                    metricUnit: DataManager.getMetricUnit(DataManager.METRIC_WEIGHT),
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
                text: Utils.formatValue(model.v, 1)
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
            enabled: historyModel.count === 0
            text: qsTr("Nothing to calculate yet")
            hintText: qsTr("Pull down to record a height and a weight")
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
