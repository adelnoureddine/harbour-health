import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: page
    allowedOrientations: Orientation.All


    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem{//Visible only if there's at least one profile
                visible: nbProfile > 0
                text: qsTr("My Profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("infosProfile.qml"))
            }
            MenuItem{//Visible only if there's no profile
                visible: nbProfile == 0
                text: qsTr("New Profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("newProfile.qml"))
            }
            MenuItem{
                text: qsTr("Choose profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("chooseProfile.qml"))
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Health")
            }
            Label {
                id: label
                x: Theme.horizontalPageMargin
                text: qsTr("Health App")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }

            ViewPlaceholder{//Visible only if there's no profile
                enabled: nbProfile == 0
                text: "No existing profile"
                hintText: "Swipe down to create a profile"
            }


            ButtonLayout{//Visible only if there's at least one profile
                visible: nbProfile > 0
                Button{
                    implicitHeight: 200
                    text: "Metrics"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Metrics.qml"))
                }
                Button{
                    implicitHeight: 200
                    text: "Meditation"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Meditation.qml"))
                }
                Button{
                    implicitHeight: 200
                    text: "Vaccines"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Vaccines.qml"))
                }
                Button{
                    implicitHeight: 200
                    text: "Health condition"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Health_condition.qml"))
                }
                Button{
                    implicitHeight: 200
                    text: "Nutrition"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Nutrition.qml"))
                }
                Button{
                    implicitHeight: 200
                    text: "Menstruation"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Menstruation.qml"))
                }
            }

        }
    }

}

