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

    canAccept: profileId >= 0 && (knownVaccine || vaccineName.text !== "")

    onAccepted: {
        var vaccineId = knownVaccine ? knownVaccineId
                                     : DataManager.getOrCreateVaccine(vaccineName.text, false);
        DataManager.addVaccineLog(profileId, vaccineId,
                                  Utils.toLocalDateString(injectionDate), notesField.text);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: dialog.knownVaccine ? qsTr("Record Injection") : qsTr("Add Vaccine Record")
                acceptText: qsTr("Save")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: dialog.knownVaccineName
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
                visible: dialog.knownVaccine
            }

            TextField {
                id: vaccineName
                width: parent.width
                label: qsTr("Vaccine Name")
                placeholderText: label
                visible: !dialog.knownVaccine
                focus: !dialog.knownVaccine
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: notesField.focus = true
            }

            ValueButton {
                id: dateButton
                label: qsTr("Injection Date")
                value: Qt.formatDate(dialog.injectionDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: dialog.injectionDate
                    })
                    dateDialog.accepted.connect(function() {
                        dialog.injectionDate = dateDialog.date;
                    })
                }
            }

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                placeholderText: qsTr("Optional notes")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
