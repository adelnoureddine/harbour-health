import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int conditionId: -1
    property int treatmentId: -1
    property int medicationId: -1
    property string medicationName
    property date startDate: new Date()
    property date endDate: new Date()
    property bool hasEndDate: false
    // False for a treatment stored without a start date (older versions, restores): it
    // stays without one unless a date is picked. Saving an edit used to set it to today.
    property bool startKnown: true
    // The condition being treated, shown under the header for context.
    property string conditionName: ""

    readonly property bool editing: treatmentId >= 0
    // Compared as calendar days: a start of "now" against an end picked as today
    // (midnight) used to count as the end coming first.
    readonly property bool datesValid: !hasEndDate || !startKnown
                                       || Utils.toLocalDateString(endDate) >= Utils.toLocalDateString(startDate)

    canAccept: profileId >= 0 && nameField.text.trim() !== "" && dosageField.text.trim() !== ""
               && datesValid

    /*
     * Loads the whole treatment by id rather than receiving a handful of fields.
     * The dates were previously not passed in at all, so saving an edit silently
     * reset the treatment's start date to today.
     */
    function load() {
        var condition = conditionId >= 0 ? DataManager.getCondition(conditionId) : null;
        conditionName = condition && condition.name ? condition.name : "";
        if (!editing) {
            return;
        }
        var treatment = DataManager.getTreatment(treatmentId);
        if (!treatment) {
            return;
        }
        medicationId = treatment.medicationId;
        medicationName = treatment.medicationName;
        nameField.text = treatment.medicationName;
        dosageField.text = treatment.dosage ? treatment.dosage : "";
        frequencyField.text = treatment.frequency ? treatment.frequency : "";
        notesField.text = treatment.note ? treatment.note : "";

        var start = Utils.fromLocalDateString(treatment.startDate);
        if (start !== null) {
            startDate = start;
        } else {
            startKnown = false;
        }
        if (treatment.endDate) {
            var end = Utils.fromLocalDateString(treatment.endDate);
            if (end !== null) {
                endDate = end;
            }
            hasEndDate = true;
        }
    }

    onAccepted: {
        var name = nameField.text.trim();
        var startStr = startKnown ? Utils.toLocalDateString(startDate) : null;
        var endStr = hasEndDate ? Utils.toLocalDateString(endDate) : null;
        if (!editing) {
            // The medication is found by its name, or created: the same one prescribed
            // for two conditions is one medication, listed once, with one intake history.
            DataManager.addTreatmentFor(profileId, name, conditionId, dosageField.text.trim(),
                                        frequencyField.text.trim(), startStr, endStr, notesField.text.trim());
        } else {
            DataManager.updateTreatment(treatmentId, dosageField.text.trim(), frequencyField.text.trim(),
                                        startStr, endStr, notesField.text.trim());
            if (name !== medicationName) {
                DataManager.setTreatmentMedicationName(treatmentId, name);
            }
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
                title: dialog.editing ? qsTr("Edit treatment") : qsTr("Add treatment")
                acceptText: qsTr("Save")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: text !== ""
                truncationMode: TruncationMode.Fade
                text: dialog.conditionName
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
            }

            TextField {
                id: nameField
                // Set once the field has been left, so an untouched form is not
                // greeted with an error.
                property bool touched: false

                width: parent.width
                label: qsTr("Medication name")
                text: dialog.medicationName
                placeholderText: label
                // Editable when editing too: a misspelt name could only be fixed by
                // deleting the treatment and adding it again, which deleted every intake
                // logged for it. DataManager.setTreatmentMedicationName keeps them.
                focus: !dialog.editing
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        touched = true;
                    }
                }
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: dosageField.focus = true
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: nameField.touched && nameField.text.trim() === ""
                text: qsTr("Enter the name of the medication.")
            }

            TextField {
                id: dosageField
                property bool touched: false

                width: parent.width
                label: qsTr("Dosage")
                placeholderText: qsTr("e.g. 500mg")
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        touched = true;
                    }
                }
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: frequencyField.focus = true
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: dosageField.touched && dosageField.text.trim() === ""
                text: qsTr("Enter the dosage.")
            }

            TextField {
                id: frequencyField
                width: parent.width
                label: qsTr("Frequency")
                placeholderText: qsTr("e.g. Twice a day")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: notesField.focus = true
            }

            ValueButton {
                label: qsTr("Start date")
                //: Shown instead of a start date when none was ever recorded
                value: dialog.startKnown ? Utils.formatDate(dialog.startDate) : qsTr("Not recorded")
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.startDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.startDate = dateDialog.date;
                        dialog.startKnown = true;
                    })
                }
            }

            TextSwitch {
                id: endDateSwitch
                text: qsTr("Has end date")
                checked: dialog.hasEndDate
                automaticCheck: false
                onClicked: {
                    dialog.hasEndDate = !dialog.hasEndDate;
                    // Starts from a valid date rather than one before the start.
                    if (dialog.hasEndDate && !dialog.datesValid) {
                        dialog.endDate = dialog.startDate;
                    }
                }
            }

            ValueButton {
                label: qsTr("End date")
                value: Utils.formatDate(dialog.endDate)
                visible: dialog.hasEndDate
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.endDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.endDate = dateDialog.date;
                    })
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: !dialog.datesValid
                text: qsTr("The end date is before the start date.")
            }

            // Last, so Enter here can save.
            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                placeholderText: qsTr("Optional notes")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: dialog.canAccept
                EnterKey.onClicked: dialog.accept()
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
