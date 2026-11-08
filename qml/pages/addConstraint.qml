import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

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
    readonly property string selectedColor: colorNames[colorCombo.currentIndex >= 0 ? colorCombo.currentIndex : 0]

    function parsedMin() {
        return minField.text === "" ? null : parseFloat(minField.text.replace(',', '.'));
    }

    function parsedMax() {
        return maxField.text === "" ? null : parseFloat(maxField.text.replace(',', '.'));
    }

    // Either end may be left empty, and an empty field never passes its validator:
    // requiring acceptableInput of both made every open-ended band ("Below 50")
    // impossible to save.
    canAccept: labelField.text.trim() !== ""
               && (minField.text === "" || minField.acceptableInput)
               && (maxField.text === "" || maxField.acceptableInput)
               && (minField.text !== "" || maxField.text !== "")
               && (parsedMin() === null || parsedMax() === null || parsedMin() < parsedMax())

    function load() {
        // Built-in labels are stored in English and shown translated in the list, so
        // they are edited translated too (see savedLabel()).
        labelField.text = Utils.constraintLabelDisplayName(labelText);
        // A threshold of exactly 0 is meaningful and must survive the round trip.
        minField.text = (minValue === null || minValue === undefined) ? "" : Utils.formatInput(minValue);
        maxField.text = (maxValue === null || maxValue === undefined) ? "" : Utils.formatInput(maxValue);
        var index = colorNames.indexOf(colorName);
        colorCombo.currentIndex = index >= 0 ? index : 0;
    }

    // An untouched built-in label keeps its English key, so it stays translatable.
    function savedLabel() {
        var label = labelField.text.trim();
        return (editing && label === Utils.constraintLabelDisplayName(labelText)) ? labelText : label;
    }

    onAccepted: {
        if (editing) {
            DataManager.updateConstraint(constraintId, savedLabel(), parsedMin(), parsedMax(), selectedColor);
        } else {
            DataManager.addConstraint(metricName, savedLabel(), parsedMin(), parsedMax(), selectedColor);
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

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

            // Next to the label, so a band is named and coloured before its range is
            // typed: the range's last field saves the dialog with the Enter key, and the
            // colour used to sit below it, where Enter skipped it.
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

            // How the band will show on the history page and the dashboard.
            Row {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium
                visible: labelField.text.trim() !== ""

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    //: Caption before a sample of the reference band being edited
                    text: qsTr("Preview")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                StatusPill {
                    anchors.verticalCenter: parent.verticalCenter
                    text: labelField.text.trim()
                    dotColor: Utils.constraintColor(dialog.selectedColor) !== ""
                              ? Utils.constraintColor(dialog.selectedColor) : Theme.highlightColor
                }
            }

            SectionHeader {
                text: qsTr("Value range")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Fill one or both fields. With both, the band covers everything between them; with only a minimum it covers everything above; with only a maximum, everything below.")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall

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
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: dialog.canAccept
                    EnterKey.onClicked: dialog.accept()
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
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
