import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width

        TextSwitch {
            text: "height"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("height.qml"))
        }
        TextSwitch {
            text: "weight"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("weight.qml"))
        }
        TextSwitch {
            text: "neck"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("neck.qml"))
        }
        TextSwitch {
            text: "calf"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("calf.qml"))
        }
        TextSwitch {
            text: "arm"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("arm.qml"))
        }
        TextSwitch {
            text: "thigh"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("thigh.qml"))
        }
        TextSwitch {
            text: "hip"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("hip.qml"))
        }
        TextSwitch {
            text: "chest"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("height.qml"))
        }

    }

    }
}
