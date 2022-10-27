import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator {}

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            DialogHeader {
                acceptText: "Delete"
                title: "Delete a profile"
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
