import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

// Same fields and checks as modifyProfile.qml: keep the two in step.
Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property var birthDate: null

    // Genders are stored canonically. Saving the ComboBox text put the *translated*
    // label in the database, which then failed every gender comparison in the app.
    readonly property var genderValues: ["female", "male", "other"]

    readonly property string firstName: firstnameField.text.trim()
    readonly property string lastName: lastnameField.text.trim()
    readonly property bool birthDateInFuture: birthDate ? birthDate > Utils.endOfToday() : false

    // ComboBox has no `text` property, so the old canAccept check could never fail
    // and a profile could be created with no gender at all.
    canAccept: firstName !== "" && lastName !== ""
               && genderField.currentIndex >= 0 && birthDate !== null && !birthDateInFuture

    onAccepted: {
        var profileId = DataManager.addProfile(firstName, lastName,
                                               genderValues[genderField.currentIndex],
                                               Utils.toLocalDateString(birthDate));
        DataManager.useProfile(profileId);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            DialogHeader {
                title: qsTr("Create profile")
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
                    focus: true
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
                // Unselected, the combo box showed nothing at all next to its label.
                value: currentItem ? currentItem.text : qsTr("Not set")
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

            Item { width: 1; height: Theme.paddingLarge }

            // Why a profile, and that nothing leaves the phone. Restoring a backup is
            // offered on the welcome screen and in the dashboard's pull-down menu, so
            // this form stays about the profile.
            Card {
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                    text: qsTr("Each person using Health on this phone gets a profile of their own, with separate readings and dashboard. The birthday and gender stay on this phone and can be changed later.")
                }
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
