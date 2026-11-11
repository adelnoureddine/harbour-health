import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * MetricChart on a card, the same surface as the dashboard cards, so the chart reads
 * as one framed block against the ambience wallpaper.
 */
Item {
    id: root

    property alias series: chart.series
    property alias bands: chart.bands
    property alias unit: chart.unit
    property alias decimals: chart.decimals
    property alias emptyText: chart.emptyText
    property alias bars: chart.bars
    property alias bucket: chart.bucket
    property alias averageValue: chart.averageValue
    property alias goalValue: chart.goalValue
    property alias goalText: chart.goalText
    property alias rangeStart: chart.rangeStart
    property alias rangeEnd: chart.rangeEnd

    height: chart.height + 2 * Theme.paddingMedium

    CardBackground {
        anchors.fill: parent
    }

    MetricChart {
        id: chart
        x: Theme.paddingSmall
        y: Theme.paddingMedium
        width: parent.width - Theme.paddingSmall - Theme.paddingMedium
    }
}

// vim:et:ts=4:sw=4
