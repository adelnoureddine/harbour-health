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
            text: qsTr("Edit")
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Edit.qml"))
        }
        MenuItem {
            text: qsTr("Delete")
            //onClicked: supprimer le profile
        }
        MenuItem {
            text: qsTr("Change")
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Change.qml"))
        }
        MenuItem {
            text: qsTr("Menu")
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Menu.qml"))
        }
    }
    }
}