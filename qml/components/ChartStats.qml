import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/utils.js" as Utils

/*
 * Minimum / average / maximum summary shown under a chart.
 * `stats` is the object returned by DataManager.getSeriesStats(). With `stats2` as
 * well (blood pressure), each value is shown as a pair: "121/79".
 */
Row {
    id: root

    property var stats: null
    property var stats2: null
    property string unit: ""
    // Ratios such as waist-to-height (0.47) need two.
    property int decimals: 1

    visible: stats !== null && stats.count > 0
    height: visible ? implicitHeight : 0

    readonly property var fields: ["min", "avg", "max"]

    function captionFor(field) {
        switch (field) {
        //: Chart statistics caption: lowest value in the range. Short.
        case "min": return qsTr("Min");
        //: Chart statistics caption: mean value in the range. Short.
        case "avg": return qsTr("Average");
        //: Chart statistics caption: highest value in the range. Short.
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
                      : Utils.formatValue(root.stats[modelData], root.decimals)
                        + (root.stats2 ? "/" + Utils.formatValue(root.stats2[modelData], root.decimals) : "")
                        + (root.unit ? " " + root.unit : "")
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
            }
        }
    }
}

// vim:et:ts=4:sw=4
