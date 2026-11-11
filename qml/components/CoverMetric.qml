import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * One metric on the cover. A daily total (water, calories) is a ring against its
 * goal; any other metric is its latest value with a small trend line underneath.
 */
Column {
    id: root

    property int profileId: -1
    property string metricName: ""

    // Everything here is as shown: in the unit chosen in Units.
    property string unit: ""
    property bool grouped: false
    property var value: null
    property real total: 0
    property var goal: null
    property var trend: []
    property int decimals: 2

    function refresh() {
        if (profileId < 0 || metricName === "") {
            return;
        }
        unit = DataManager.displayUnit(metricName, DataManager.getMetricUnit(metricName) || "");
        grouped = DataManager.getMetricGrouped(metricName) ? true : false;
        if (grouped) {
            var t = DataManager.getTodayTotal(profileId, metricName);
            var g = DataManager.getActiveGoal(profileId, metricName);
            decimals = DataManager.displayDecimals(metricName, Utils.metricDecimals(metricName));
            total = DataManager.toDisplay(metricName, t === null ? 0 : t);
            goal = g === null ? null : DataManager.toDisplay(metricName, g);
            return;
        }
        // The same trend as the dashboard card; it ends with the latest reading.
        var series = DataManager.getTrend(profileId, metricName);
        decimals = DataManager.displayDecimals(metricName, 2);
        value = series.length > 0 ? DataManager.toDisplay(metricName, series[series.length - 1].v) : null;
        trend = series.map(function (point) { return point.v; });
    }

    spacing: Theme.paddingSmall / 2

    Label {
        width: parent.width
        truncationMode: TruncationMode.Fade
        // The raw internal name ("systolic blood pressure") used to be shown on the
        // cover, lowercase and untranslated.
        text: root.grouped ? qsTr("%1 today").arg(Utils.metricDisplayName(root.metricName))
                           : Utils.metricDisplayName(root.metricName)
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
    }

    // --- latest value and its trend ---------------------------------------------------
    Row {
        visible: !root.grouped
        width: parent.width
        spacing: Theme.paddingSmall
        Label {
            id: valueLabel
            width: Math.min(implicitWidth, parent.width - unitLabel.width - parent.spacing)
            truncationMode: TruncationMode.Fade
            text: root.value === null ? "—" : Utils.formatValue(root.value, root.decimals)
            font.pixelSize: Theme.fontSizeExtraLarge
            color: Theme.primaryColor
        }
        Label {
            id: unitLabel
            anchors.baseline: valueLabel.baseline
            visible: root.value !== null
            text: root.unit
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryColor
        }
    }
    Sparkline {
        visible: !root.grouped && root.trend.length >= 2
        width: parent.width
        height: visible ? Theme.paddingLarge * 2 : 0
        points: root.trend
        filled: false
        lineColor: Theme.highlightColor
    }

    // --- daily total against its goal -----------------------------------------------
    Row {
        visible: root.grouped
        width: parent.width
        spacing: Theme.paddingMedium

        ProgressCircle {
            id: ring
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.iconSizeLarge
            height: width
            value: root.goal > 0 ? Math.min(1, root.total / root.goal) : 0
            progressColor: Theme.highlightColor
            backgroundColor: Theme.rgba(Theme.primaryColor, 0.2)
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - ring.width - parent.spacing
            // The number large and its unit small, as on the dashboard: "410 kcal" all
            // large did not fit beside the ring and faded to "410 kc".
            Row {
                width: parent.width
                spacing: Theme.paddingSmall / 2
                Label {
                    id: totalLabel
                    width: Math.min(implicitWidth, parent.width - (totalUnit.visible ? totalUnit.width + parent.spacing : 0))
                    truncationMode: TruncationMode.Fade
                    text: Utils.formatValue(root.total, root.decimals)
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.primaryColor
                }
                Label {
                    id: totalUnit
                    anchors.baseline: totalLabel.baseline
                    visible: root.unit !== ""
                    text: root.unit
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
            Label {
                width: parent.width
                visible: root.goal !== null
                truncationMode: TruncationMode.Fade
                text: root.goal === null ? "" : qsTr("of %1 %2").arg(Utils.formatValue(root.goal, root.decimals)).arg(root.unit)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
            }
        }
    }
}

// vim:et:ts=4:sw=4
