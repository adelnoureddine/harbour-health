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

    readonly property bool editing: treatmentId >= 0

    canAccept: profileId >= 0 && nameField.text !== "" && dosageField.text !== ""
               && (!hasEndDate || endDate >= startDate)

    /*
     * Loads the whole treatment by id rather than receiving a handful of fields.
     * The dates were previously not passed in at all, so saving an edit silently
     * reset the treatment's start date to today.
     */
    function load() {
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
        var medId = medicationId;
        if (medId === -1) {
            medId = DataManager.addMedication(nameField.text, "pill", "mg");
        }
        var startStr = Utils.toLocalDateString(startDate);
        var endStr = hasEndDate ? Utils.toLocalDateString(endDate) : null;
        if (!editing) {
            DataManager.addTreatment(profileId, medId, conditionId, dosageField.text,
                                     frequencyField.text, startStr, endStr, notesField.text);
        } else {
            DataManager.updateTreatment(treatmentId, dosageField.text, frequencyField.text,
                                        startStr, endStr, notesField.text);
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
                title: dialog.editing ? qsTr("Edit Treatment") : qsTr("Add Treatment")
                acceptText: qsTr("Save")
            }

            TextField {
                id: nameField
                width: parent.width
                label: qsTr("Medication Name")
                text: medicationName
                placeholderText: label
                // The medication itself is shared between treatments; renaming it
                // here would rewrite every other treatment that uses it.
                enabled: !dialog.editing
                focus: !dialog.editing
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: dosageField.focus = true
            }

            TextField {
                id: dosageField
                width: parent.width
                label: qsTr("Dosage")
                placeholderText: qsTr("e.g. 500mg")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: frequencyField.focus = true
            }

            TextField {
                id: frequencyField
                width: parent.width
                label: qsTr("Frequency")
                placeholderText: qsTr("e.g. Twice a day")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: notesField.focus = true
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                placeholderText: qsTr("Optional notes")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            ValueButton {
                label: qsTr("Start Date")
                value: Qt.formatDate(dialog.startDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.startDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.startDate = dateDialog.date;
                    })
                }
            }

            TextSwitch {
                id: endDateSwitch
                text: qsTr("Has end date")
                checked: dialog.hasEndDate
                automaticCheck: false
                onClicked: dialog.hasEndDate = !dialog.hasEndDate
            }

            ValueButton {
                label: qsTr("End Date")
                value: Qt.formatDate(dialog.endDate, Qt.DefaultLocaleShortDate)
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
                visible: dialog.hasEndDate && dialog.endDate < dialog.startDate
                text: qsTr("The end date is before the start date.")
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
