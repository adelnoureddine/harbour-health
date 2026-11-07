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

    canAccept: profileId >= 0 && nameField.text.trim() !== ""
               && (!hasEndDate || endDate >= startDate)

    onAccepted: {
        var startStr = Utils.toLocalDateString(startDate);
        var endStr = hasEndDate ? Utils.toLocalDateString(endDate) : null;
        
        if (conditionId === -1) {
            DataManager.addCondition(profileId, nameField.text.trim(), conditionStatus, startStr, endStr, notesField.text);
        } else {
            DataManager.updateCondition(conditionId, nameField.text.trim(), conditionStatus, startStr, endStr, notesField.text);
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
                title: conditionId === -1 ? qsTr("Add condition") : qsTr("Edit condition")
                acceptText: qsTr("Save")
            }

            TextField {
                id: nameField
                width: parent.width
                label: qsTr("Condition name")
                text: conditionName
                placeholderText: label
                focus: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: notesField.focus = true
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

            TextField {
                id: notesField
                width: parent.width
                label: qsTr("Notes")
                text: note
                placeholderText: qsTr("Optional notes")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.enabled: dialog.canAccept
                EnterKey.onClicked: dialog.accept()
            }

            ValueButton {
                label: qsTr("Start date")
                value: Qt.formatDate(startDate, Qt.DefaultLocaleShortDate)
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: startDate
                    })
                    dateDialog.accepted.connect(function() {
                        startDate = dateDialog.date
                    })
                }
            }

            TextSwitch {
                id: endDateSwitch
                text: qsTr("Has end date")
                checked: hasEndDate
                automaticCheck: false
                onClicked: hasEndDate = !hasEndDate
            }

            ValueButton {
                label: qsTr("End date")
                value: Qt.formatDate(endDate, Qt.DefaultLocaleShortDate)
                visible: hasEndDate
                onClicked: {
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", {
                        date: endDate
                    })
                    dateDialog.accepted.connect(function() {
                        endDate = dateDialog.date
                    })
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                visible: hasEndDate && endDate < startDate
                text: qsTr("The end date is before the start date.")
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}
