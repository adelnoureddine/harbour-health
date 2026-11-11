import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property date injectionDate: new Date()

    // Set when recording a further injection of a vaccine that already exists, so
    // the name does not have to be typed again.
    property int knownVaccineId: -1
    property string knownVaccineName: ""

    readonly property bool knownVaccine: knownVaccineId >= 0

    // Set to correct an injection already recorded (its date or its note), together
    // with the vaccine it belongs to. An injection could only be deleted and added again.
    property int injectionId: -1
    readonly property bool editing: injectionId >= 0

    // The profile's vaccines with their doses ({id, name, doses, lastDate}), to say
    // what is already recorded.
    property var recorded: []
    // The recorded vaccine the typed name matches, as the save will (ignoring case).
    readonly property var typedMatch: knownVaccine ? null : findRecorded(vaccineName.text.trim())

    // Compared as calendar days: an injection is something that happened.
    readonly property bool inFuture: Utils.toLocalDateString(injectionDate) > Utils.toLocalDateString(new Date())

    canAccept: profileId >= 0 && (knownVaccine || vaccineName.text.trim() !== "") && !inFuture

    function loadRecorded() {
        if (profileId < 0) {
            return;
        }
        recorded = DataManager.getVaccineSummaries(profileId);
    }

    function findRecorded(name) {
        var wanted = String(name).toLowerCase();
        for (var i = 0; wanted !== "" && i < recorded.length; i++) {
            if (recorded[i].name.toLowerCase() === wanted) {
                return recorded[i];
            }
        }
        return null;
    }

    function findRecordedById(id) {
        for (var i = 0; i < recorded.length; i++) {
            if (recorded[i].id === id) {
                return recorded[i];
            }
        }
        return null;
    }

    // "2 doses · Last injection on 3/3/2024", or nothing without a dose yet.
    function dosesText(entry) {
        if (!entry || entry.doses === 0) {
            return "";
        }
        //: Number of injections recorded for a vaccine
        return qsTr("%n dose(s)", "", entry.doses) + " · "
                //: %1 is the date of the latest injection of a vaccine
                + qsTr("Last injection on %1").arg(Utils.formatDate(entry.lastDate));
    }

    onAccepted: {
        if (editing) {
            DataManager.updateVaccineLog(injectionId, Utils.toLocalDateString(injectionDate),
                                         notesField.text.trim());
            return;
        }
        // By name also for a vaccine that is known: its name is found again, or created
        // again should its last injection have been deleted in the meantime.
        // Trimmed: "Tetanus " used to become a second vaccine.
        var vaccineId = DataManager.getOrCreateVaccine(knownVaccine ? knownVaccineName
                                                                    : vaccineName.text.trim(), false);
        DataManager.addVaccineLog(profileId, vaccineId,
                                  Utils.toLocalDateString(injectionDate), notesField.text.trim());
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: dialog.editing ? qsTr("Edit injection")
                     : dialog.knownVaccine ? qsTr("Record injection") : qsTr("Add vaccine record")
                acceptText: qsTr("Save")
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: dialog.knownVaccine

                Label {
                    width: parent.width
                    text: dialog.knownVaccineName
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.highlightColor
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: dialog.knownVaccine ? dialog.dosesText(dialog.findRecordedById(dialog.knownVaccineId)) : ""
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                }
            }

            TextField {
                id: vaccineName
                // Set once the field has been left, so an untouched form is not
                // greeted with an error.
                property bool touched: false

                width: parent.width
                label: qsTr("Vaccine name")
                placeholderText: label
                visible: !dialog.knownVaccine
                focus: !dialog.knownVaccine
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        touched = true;
                    }
                }
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: notesField.focus = true
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: !dialog.knownVaccine && vaccineName.touched && vaccineName.text.trim() === ""
                text: qsTr("Enter the name of the vaccine.")
            }

            // A name that is already recorded adds a dose to it rather than a new vaccine.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                visible: dialog.typedMatch !== null && dialog.typedMatch.doses > 0
                //: %1 is a vaccine name the user already has injections of
                text: dialog.typedMatch === null ? ""
                      : qsTr("Adds a dose to %1.").arg(dialog.typedMatch.name) + " "
                        + dialog.dosesText(dialog.typedMatch)
            }

            ValueButton {
                id: dateButton
                label: qsTr("Injection date")
                value: Utils.formatDate(dialog.injectionDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.injectionDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.injectionDate = dateDialog.date;
                    })
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: dialog.inFuture
                text: qsTr("The injection date is in the future.")
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

    Component.onCompleted: {
        loadRecorded();
        if (editing) {
            var injection = DataManager.getVaccineLog(injectionId);
            if (injection) {
                var when = Utils.fromLocalDateString(injection.date);
                if (when !== null) {
                    injectionDate = when;
                }
                notesField.text = injection.note ? injection.note : "";
            }
        }
    }
}

// vim:et:ts=4:sw=4
