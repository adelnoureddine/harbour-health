import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * Segmented control choosing how far back a chart reaches.
 *
 * `days` is 0 for "all time". Kept as its own component because the three history
 * pages all need exactly this control.
 */
Row {
    id: root

    property int days: 30

    height: Theme.itemSizeExtraSmall

    // A plain array avoids a ListModel that has to be filled in Component.onCompleted
    // just so the labels can be translated.
    readonly property var ranges: [7, 30, 365, 0]

    function labelFor(rangeDays) {
        switch (rangeDays) {
        case 7:   return qsTr("Week");
        case 30:  return qsTr("Month");
        case 365: return qsTr("Year");
        default:  return qsTr("All");
        }
    }

    Repeater {
        model: root.ranges

        delegate: BackgroundItem {
            // Referenced by id, not through `parent`: while a delegate is being torn
            // down `parent` briefly becomes null, and `parent.selected` then warns
            // "Unable to assign [undefined] to bool".
            id: rangeItem

            width: root.width / root.ranges.length
            height: root.height

            readonly property bool selected: root.days === modelData

            onClicked: root.days = modelData

            Label {
                // anchors.centerIn/bottom/horizontalCenter must use the literal
                // "parent" keyword: Row treats a named-id anchor target on one of
                // its own children's descendants as "not a parent or sibling" and
                // refuses it outright. Only non-anchor bindings (below) need the id.
                anchors.centerIn: parent
                width: rangeItem.width - Theme.paddingSmall
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                text: root.labelFor(modelData)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: rangeItem.selected ? Theme.highlightColor
                     : (rangeItem.highlighted ? Theme.primaryColor : Theme.secondaryColor)
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: rangeItem.width - Theme.paddingLarge
                height: 2
                color: Theme.highlightColor
                visible: rangeItem.selected
            }
        }
    }
}

// vim:et:ts=4:sw=4
