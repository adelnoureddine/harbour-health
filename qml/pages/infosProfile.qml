import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("Afficher les profils")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
            MenuItem {
                text: qsTr("Modifier le profil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
            MenuItem {
                text: qsTr("Supprimer le profil")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("deleteProfile.qml"))
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
                title: qsTr("Information profil")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("First Name")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
            Label{
                x: Theme.horizontalPageMargin
                text: qsTr("Second Name")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
            Label{
                x: Theme.horizontalPageMargin
                text: qsTr("Gender")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge

            }
            Label{
                x: Theme.horizontalPageMargin
                text: qsTr("Birthday")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
            // METTRE DES FONCTIONS QUI RECUP LES DONNEES DU PROFIL ACTUEL POUR LES AFFICHER
        }
    }
}
