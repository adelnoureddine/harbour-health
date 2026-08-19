import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property string metricName: ""
    property string metricUnit: ""

    // Set when editing an existing range rather than adding one.
    property int constraintId: -1
    property string labelText: ""
    property var minValue: null
    property var maxValue: null
    property string colorName: "green"

    readonly property bool editing: constraintId >= 0
    readonly property var colorNames: ["green", "orange", "red", "blue"]

    function parsedMin() {
        return minField.text === "" ? null : parseFloat(minField.text.replace(',', '.'));
    }

    function parsedMax() {
        return maxField.text === "" ? null : parseFloat(maxField.text.replace(',', '.'));
    }

    canAccept: labelField.text !== ""
               && (minField.text !== "" || maxField.text !== "")
               && (parsedMin() === null || parsedMax() === null || parsedMin() < parsedMax())

    function load() {
        labelField.text = labelText;
        // A threshold of exactly 0 is meaningful and must survive the round trip.
        minField.text = (minValue === null || minValue === undefined) ? "" : Utils.formatValue(minValue);
        maxField.text = (maxValue === null || maxValue === undefined) ? "" : Utils.formatValue(maxValue);
        var index = colorNames.indexOf(colorName);
        colorCombo.currentIndex = index >= 0 ? index : 0;
    }

    onAccepted: {
        var color = colorNames[colorCombo.currentIndex >= 0 ? colorCombo.currentIndex : 0];
        if (editing) {
            DataManager.updateConstraint(constraintId, labelField.text, parsedMin(), parsedMax(), color);
        } else {
            DataManager.addConstraint(metricName, labelField.text, parsedMin(), parsedMax(), color);
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: dialog.editing ? qsTr("Edit range") : qsTr("Add range")
                acceptText: qsTr("Save")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                truncationMode: TruncationMode.Fade
                text: Utils.metricDisplayName(dialog.metricName)
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
            }

            TextField {
                id: labelField
                width: parent.width
                label: qsTr("Label")
                placeholderText: qsTr("e.g. Normal, Elevated, High")
                focus: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: minField.focus = true
            }

            SectionHeader {
                text: qsTr("Value range")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("Fill one or both fields. With both, the band covers everything between them; with only a minimum it covers everything above; with only a maximum, everything below.")
            }

            TextField {
                id: minField
                width: parent.width
                label: dialog.metricUnit ? qsTr("Minimum (%1)").arg(dialog.metricUnit) : qsTr("Minimum")
                placeholderText: qsTr("Optional")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d{1,6}([.,]\d{1,3})?$/ }
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: maxField.focus = true
            }

            TextField {
                id: maxField
                width: parent.width
                label: dialog.metricUnit ? qsTr("Maximum (%1)").arg(dialog.metricUnit) : qsTr("Maximum")
                placeholderText: qsTr("Optional")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d{1,6}([.,]\d{1,3})?$/ }
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: minField.text !== "" && maxField.text !== ""
                         && dialog.parsedMin() >= dialog.parsedMax()
                text: qsTr("The minimum must be below the maximum.")
            }

            ComboBox {
                id: colorCombo
                width: parent.width
                label: qsTr("Colour")
                menu: ContextMenu {
                    MenuItem { text: qsTr("Green — in range") }
                    MenuItem { text: qsTr("Orange — borderline") }
                    MenuItem { text: qsTr("Red — too high") }
                    MenuItem { text: qsTr("Blue — too low") }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
