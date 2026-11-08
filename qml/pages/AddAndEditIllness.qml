import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int conditionId: -1
    property string conditionName
    property string conditionStatus: "Active"
    // Statuses used to be typed freely, so every user got an English "Active" to
    // overwrite. They are now picked from fixed keys, shown translated. A status an
    // older version stored stays available as it is.
    readonly property var statusKeys: ["Active", "Chronic", "Recovered"]
    property var statusOptions: statusKeys
    property date startDate: new Date()
    property date endDate: new Date()
    property bool hasEndDate: false
    property string note

    readonly property bool editing: conditionId !== -1
    // Compared as calendar days: a start of "now" against an end picked as today
    // (midnight) used to count as the end coming first.
    readonly property bool datesValid: !hasEndDate
                                       || Utils.toLocalDateString(endDate) >= Utils.toLocalDateString(startDate)

    // Loaded once, not on every PageStatus.Active: returning from the date picker
    // re-activates this dialog, and reloading there discarded the chosen date.
    function load() {
        if (conditionId === -1) {
            return;
        }
        var condition = DataManager.getCondition(conditionId);
        if (!condition) {
            return;
        }
        conditionName = condition.name;
        conditionStatus = condition.status ? condition.status : "";
        if (conditionStatus !== "" && statusKeys.indexOf(conditionStatus) < 0) {
            statusOptions = statusKeys.concat([conditionStatus]);
        }
        var start = Utils.fromLocalDateString(condition.startDate);
        if (start !== null) {
            startDate = start;
        }
        if (condition.endDate) {
            var end = Utils.fromLocalDateString(condition.endDate);
            if (end !== null) {
                endDate = end;
            }
            hasEndDate = true;
        }
        note = condition.note ? condition.note : "";
        statusBox.currentIndex = statusOptions.indexOf(conditionStatus);
    }

    canAccept: profileId >= 0 && nameField.text.trim() !== "" && datesValid

    onAccepted: {
        var startStr = Utils.toLocalDateString(startDate);
        var endStr = hasEndDate ? Utils.toLocalDateString(endDate) : null;

        if (conditionId === -1) {
            DataManager.addCondition(profileId, nameField.text.trim(), conditionStatus, startStr, endStr,
                                     notesField.text.trim());
        } else {
            DataManager.updateCondition(conditionId, nameField.text.trim(), conditionStatus, startStr, endStr,
                                        notesField.text.trim());
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
                title: dialog.editing ? qsTr("Edit condition") : qsTr("Add condition")
                acceptText: qsTr("Save")
            }

            TextField {
                id: nameField
                // Set once the field has been left, so an untouched form is not
                // greeted with an error.
                property bool touched: false

                width: parent.width
                label: qsTr("Condition name")
                text: dialog.conditionName
                placeholderText: label
                // Editing usually means the dates or the status; the keyboard would
                // only cover them.
                focus: !dialog.editing
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
                visible: nameField.touched && nameField.text.trim() === ""
                text: qsTr("Enter the name of the condition.")
            }

            ComboBox {
                id: statusBox
                width: parent.width
                label: qsTr("Status")
                currentIndex: dialog.statusOptions.indexOf(dialog.conditionStatus)
                menu: ContextMenu {
                    Repeater {
                        model: dialog.statusOptions
                        MenuItem {
                            text: Utils.conditionStatusDisplayName(modelData)
                            onClicked: dialog.conditionStatus = modelData
                        }
                    }
                }
            }

            ValueButton {
                label: qsTr("Start date")
                value: Utils.formatDate(dialog.startDate)
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
                text: dialog.note
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
