import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

// Same fields and checks as createProfile.qml: keep the two in step.
Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property int profileId: -1
    // As stored. Kept when the combo box has nothing to show for it (see load()).
    property string gender: ""
    property var birthDate: null

    readonly property var genderValues: ["female", "male", "other"]

    readonly property string firstName: firstnameField.text.trim()
    readonly property string lastName: lastnameField.text.trim()
    readonly property bool birthDateInFuture: birthDate ? birthDate > Utils.endOfToday() : false

    canAccept: profileId >= 0 && firstName !== "" && lastName !== ""
               && (genderField.currentIndex >= 0 || gender !== "")
               && birthDate !== null && !birthDateInFuture

    function load() {
        var profile = DataManager.getProfile(profileId);
        if (!profile) {
            return;
        }
        firstnameField.text = profile.firstName || "";
        lastnameField.text = profile.lastName || "";
        // Profiles created before genders were canonical hold a translated label;
        // indexOf then returns -1 and the combo box simply starts unselected.
        gender = profile.gender || "";
        genderField.currentIndex = genderValues.indexOf(gender);
        birthDate = Utils.fromLocalDateString(profile.birthDate);
    }

    onAccepted: {
        var selected = genderField.currentIndex >= 0 ? genderValues[genderField.currentIndex] : gender;
        DataManager.updateProfile(profileId, firstName, lastName,
                                  selected, Utils.toLocalDateString(birthDate));
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                title: qsTr("Edit profile")
                acceptText: qsTr("Save")
            }

            Column {
                width: parent.width

                TextField {
                    id: firstnameField
                    // Set once the field has been left, so a fresh dialog shows no errors.
                    property bool touched: false
                    width: parent.width
                    label: qsTr("First name")
                    placeholderText: label
                    errorHighlight: touched && dialog.firstName === ""
                    onActiveFocusChanged: if (!activeFocus) touched = true
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: lastnameField.focus = true
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: firstnameField.errorHighlight
                    wrapMode: Text.Wrap
                    text: qsTr("Enter a first name")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                }
            }

            Column {
                width: parent.width

                TextField {
                    id: lastnameField
                    property bool touched: false
                    width: parent.width
                    label: qsTr("Last name")
                    placeholderText: label
                    errorHighlight: touched && dialog.lastName === ""
                    onActiveFocusChanged: if (!activeFocus) touched = true
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.enabled: dialog.canAccept
                    EnterKey.onClicked: dialog.accept()
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: lastnameField.errorHighlight
                    wrapMode: Text.Wrap
                    text: qsTr("Enter a last name")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.errorColor
                }
            }

            ComboBox {
                id: genderField
                width: parent.width
                label: qsTr("Gender")
                currentIndex: -1
                // An older profile's label is shown as stored until another is picked.
                value: currentItem ? currentItem.text
                                   : (dialog.gender !== "" ? dialog.gender : qsTr("Not set"))
                menu: ContextMenu {
                    MenuItem { text: qsTr("Female") }
                    MenuItem { text: qsTr("Male") }
                    MenuItem { text: qsTr("Other") }
                }
            }

            Column {
                width: parent.width

                ValueButton {
                    id: birthDateField
                    label: qsTr("Birthday")
                    value: dialog.birthDate ? Format.formatDate(dialog.birthDate, Formatter.DateMedium)
                                            : qsTr("Not set")
                    onClicked: {
                        var properties = {};
                        if (dialog.birthDate) {
                            properties['date'] = dialog.birthDate;
                        }
                        var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", properties)
                        dateDialog.accepted.connect(function() {
                            dialog.birthDate = dateDialog.date;
                        })
                    }
                }

                // The age confirms the right year was picked, the easy one to get wrong.
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: dialog.birthDateInFuture ? qsTr("The birthday cannot be in the future")
                                                   : Utils.ageFrom(dialog.birthDate) >= 0
                                                     //: A profile's age, under the birthday
                                                     ? qsTr("%n year(s)", "", Utils.ageFrom(dialog.birthDate))
                                                     : ""
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: dialog.birthDateInFuture ? Theme.errorColor : Theme.secondaryColor
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: load()
}

// vim:et:ts=4:sw=4
