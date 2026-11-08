import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * The top of a history page: the current value, large, with its unit, one line on
 * how it moved and when it was measured, and its reference band when it has one.
 */
Column {
    id: root

    property string valueText: ""
    property string unit: ""
    property string detailText: ""
    property string bandLabel: ""
    property color bandColor: "transparent"

    spacing: Theme.paddingSmall

    Item {
        width: parent.width
        height: valueLabel.height

        Label {
            id: valueLabel
            text: root.valueText
            font.pixelSize: Theme.fontSizeHuge * 1.15
            color: Theme.primaryColor
        }
        Label {
            anchors.left: valueLabel.right
            anchors.leftMargin: Theme.paddingSmall
            anchors.baseline: valueLabel.baseline
            text: root.unit
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.secondaryHighlightColor
        }
    }

    Label {
        width: parent.width
        visible: text !== ""
        wrapMode: Text.Wrap
        text: root.detailText
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.secondaryHighlightColor
    }

    StatusPill {
        text: root.bandLabel
        dotColor: root.bandColor
        maximumWidth: parent.width
    }
}

// vim:et:ts=4:sw=4
