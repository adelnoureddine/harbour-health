import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refresh() {
        listModel.clear();
        var medications = DataManager.getMedications(profileId);
        medications.forEach(function(m) {
            listModel.append(m);
        });
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("All Medications")
        }

        model: listModel

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium

            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultMedication.qml"), {
                profileId: page.profileId,
                medicationId: model.id,
                medicationName: model.name
            })

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    text: model.name
                    color: Theme.primaryColor
                }

                Label {
                    text: qsTr("%1 — %2").arg(model.type).arg(model.unit)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No medications found")
            hintText: qsTr("Add a treatment from a health condition")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) refresh();
    }

    Component.onCompleted: refresh()
}
