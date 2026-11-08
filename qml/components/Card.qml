import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * A block of content on the card surface, laid out as a column. Put it in a page
 * Column: it spans the page between the side margins and grows with its content.
 *
 *     Card {
 *         Label { text: qsTr("Started on"); ... }
 *         Label { text: ...; ... }
 *     }
 */
Item {
    id: card

    default property alias content: inner.data
    property alias spacing: inner.spacing
    // The lighter placeholder surface, for "nothing recorded yet" blocks.
    property alias subtle: background.subtle
    property real padding: Theme.paddingLarge

    x: Theme.horizontalPageMargin
    width: parent ? parent.width - 2 * Theme.horizontalPageMargin : 0
    height: inner.height + 2 * padding

    CardBackground {
        id: background
        anchors.fill: parent
    }

    Column {
        id: inner
        x: card.padding
        y: card.padding
        width: card.width - 2 * card.padding
        spacing: Theme.paddingSmall
    }
}

// vim:et:ts=4:sw=4
