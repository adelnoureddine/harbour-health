import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property var birthDate

    // Genders are stored canonically. Saving the ComboBox text put the *translated*
    // label in the database, which then failed every gender comparison in the app.
    readonly property var genderValues: ["female", "male", "other"]

    // ComboBox has no `text` property, so the old canAccept check could never fail
    // and a profile could be created with no gender at all.
    canAccept: firstnameField.text !== "" && lastnameField.text !== ""
               && genderField.currentIndex >= 0 && birthDate !== undefined

    onAccepted: {
        var profileId = DataManager.addProfile(firstnameField.text, lastnameField.text,
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
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Create Profile")
                acceptText: qsTr("Save")
            }

            TextField {
                id: firstnameField
                width: parent.width
                label: qsTr("First Name")
                placeholderText: label
                focus: true
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: lastnameField.focus = true
            }

            TextField {
                id: lastnameField
                width: parent.width
                label: qsTr("Last Name")
                placeholderText: label
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }

            ComboBox {
                id: genderField
                width: parent.width
                label: qsTr("Gender")
                currentIndex: -1
                menu: ContextMenu {
                    MenuItem { text: qsTr("Female") }
                    MenuItem { text: qsTr("Male") }
                    MenuItem { text: qsTr("Other") }
                }
            }

            ValueButton {
                id: birthDateField
                label: qsTr("Birthday")
                value: birthDate ? Qt.formatDate(birthDate, Qt.DefaultLocaleShortDate)
                                 : qsTr("Not set")
                onClicked: {
                    var properties = {};
                    if (birthDate) {
                        properties['date'] = birthDate;
                    }
                    var dateDialog = pageStack.push("Sailfish.Silica.DatePickerDialog", properties)
                    dateDialog.accepted.connect(function() {
                        birthDate = dateDialog.date;
                    })
                }
            }

            Separator {
                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                color: Theme.rgba(Theme.primaryColor, 0.2)
                horizontalAlignment: Qt.AlignHCenter
            }

            // Moving to a new phone starts here, with no profile to reach Settings
            // through -- so the restore path has to be offered on this screen.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Already have a backup from another device?")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Restore from a backup")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("DataTransfer.qml"))
            }

            Item { width: 1; height: Theme.paddingLarge }
        }

        VerticalScrollDecorator {}
    }
}

// vim:et:ts=4:sw=4
