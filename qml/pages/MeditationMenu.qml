import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Meditation")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("New Session")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("NewSession.qml"), {profileId: page.profileId})
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Session History")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("History.qml"), {profileId: page.profileId})
            }
        }
    }
}
