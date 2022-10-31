import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: meditation_menu
    allowedOrientations: Orientation.All



    Column{
        width: page.width
        spacing: Theme.paddingLarge

        PageHeader{
            title: qsTr("Meditation")
        }

        ButtonLayout{
            rowSpacing : 100
            Button{
                text: qsTr("        Favorite session        ")
                //get the favorite settings in variable first
                //property ...
                //property ...
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("NewSession.qml"))
            }
            Button{
                text: qsTr("New session")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("NewSession.qml"))
            }
            Button{
                text: qsTr("session history")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("SessionHistory.qml"))
            }
        }
    }





}
