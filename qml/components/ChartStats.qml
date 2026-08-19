import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/utils.js" as Utils

/*
 * Minimum / average / maximum summary shown under a chart.
 * `stats` is the object returned by DataManager.getSeriesStats().
 */
Row {
    id: root

    property var stats: null
    property string unit: ""

    visible: stats !== null && stats.count > 0
    height: visible ? implicitHeight : 0

    readonly property var fields: ["min", "avg", "max"]

    function captionFor(field) {
        switch (field) {
        case "min": return qsTr("Min");
        case "avg": return qsTr("Average");
        default:    return qsTr("Max");
        }
    }

    Repeater {
        model: root.fields

        delegate: Column {
            id: statColumn

            width: root.width / root.fields.length
            spacing: 2

            Label {
                width: statColumn.width
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                text: root.captionFor(modelData)
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.secondaryColor
            }

            Label {
                width: statColumn.width
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                text: root.stats === null ? ""
                      : Utils.formatValue(root.stats[modelData], 1)
                        + (root.unit ? " " + root.unit : "")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
            }
        }
    }
}

// vim:et:ts=4:sw=4
