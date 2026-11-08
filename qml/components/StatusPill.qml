import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * A short status in a rounded pill with a coloured dot: a reference band ("Normal"),
 * a condition's status ("Active"), a count ("2 today"). The text stays in the primary
 * colour so it reads on light and dark ambiences; the colour is carried by the dot.
 */
Rectangle {
    id: pill

    property string text: ""
    property color dotColor: Theme.highlightColor
    // When set, a longer text fades out instead of widening the pill past this.
    property real maximumWidth: 0
    // The label follows its pressed card.
    property bool highlighted: false

    visible: text !== ""
    height: label.height + Theme.paddingSmall
    width: row.width + 2 * Theme.paddingMedium
    radius: height / 2
    color: Theme.rgba(dotColor, 0.3)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.paddingSmall

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.paddingMedium
            height: width
            radius: width / 2
            color: pill.dotColor
        }
        Label {
            id: label
            width: pill.maximumWidth > 0
                   ? Math.min(implicitWidth, pill.maximumWidth - 3 * Theme.paddingMedium - row.spacing)
                   : implicitWidth
            truncationMode: TruncationMode.Fade
            text: pill.text
            font.pixelSize: Theme.fontSizeExtraSmall
            color: pill.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
}

// vim:et:ts=4:sw=4
