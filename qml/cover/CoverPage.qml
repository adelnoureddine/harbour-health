import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Label {
        id: label
        anchors.centerIn: parent
        text: qsTr("Health")
    }

    CoverActionList {
        id: coverAction

        CoverAction {
		    //visible: mainPage.profileId >= 0
            onTriggered: {
                if (appWindow.initialPage.profileId >= 0) {
                    pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                        profileId: appWindow.initialPage.profileId
                    });
                }
                appWindow.activate();
            }
            iconSource: "image://theme/icon-cover-new"
        }
    }
}

// vim:et:ts=4:sw=4
