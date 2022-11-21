import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Add an Vaccine")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MyProfile.qml"))
            }

            MenuItem {
                text: qsTr("Menu")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("Menu.qml"))
            }
        }


        PageHeader {
            title: qsTr("Pneumocoque")
        }


    }
}
