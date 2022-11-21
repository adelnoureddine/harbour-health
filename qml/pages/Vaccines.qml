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
            text: "BCG"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("BCG.qml"))
        }
        TextSwitch {
            text: "DTP"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("DTP.qml"))
        }
        TextSwitch {
            text: "Coqueluche"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Coqueluche.qml"))
        }
        TextSwitch {
            text: "HIB"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("HIB.qml"))
        }
        TextSwitch {
            text: "Hepatite B"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("HepatiteB.qml"))
        }
        TextSwitch {
            text: "Pneumocoque"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Pneumocoque.qml"))
        }
        TextSwitch {
            text: "ROR"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ROR.qml"))
        }
        TextSwitch {
            text: "Meningocoque C"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("MeningocoqueC.qml"))
        }
        TextSwitch {
            text: "Meningocoque B"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("MeningocoqueB.qml"))
        }
        TextSwitch {
            text: "HPV"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("HPV.qml"))
        }
        TextSwitch {
            text: "Grippe"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Grippe.qml"))
        }
        TextSwitch {
            text: "Zona"
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("Zona.qml"))
        }

    }

    }
}
