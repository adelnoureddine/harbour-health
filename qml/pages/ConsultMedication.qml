import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int medicationId
    property string medicationName

    function refresh() {
        listModel.clear();
        var treatments = DataManager.getTreatments(profileId, medicationId);
        treatments.forEach(function(t) {
            listModel.append(t);
        });
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Medication: %1").arg(medicationName)
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Treatment")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditMedication.qml"), {
                    profileId: page.profileId,
                    medicationId: page.medicationId
                })
            }
        }

        model: listModel

        delegate: ListItem {
            contentHeight: Theme.itemSizeLarge
            
            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    text: qsTr("Dosage: %1").arg(model.dosage)
                    color: Theme.primaryColor
                }
                Label {
                    text: qsTr("Frequency: %1").arg(model.frequency)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
                Label {
                    text: qsTr("%1 to %2").arg(model.startDate).arg(model.endDate || qsTr("ongoing"))
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No treatments found")
            hintText: qsTr("Pull down to add a treatment")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}


