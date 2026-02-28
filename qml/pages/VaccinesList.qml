import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: root
    allowedOrientations: Orientation.All

    function refresh() {
        listModel.clear();
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var vaccines = DataManager.getVaccines(profiles[0].id);
            vaccines.forEach(function(v) {
                listModel.append(v);
            });
        }
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("Vaccines")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Vaccine Record")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {profileId: root.profileId})
            }
        }

        model: listModel

        delegate: ListItem {
            contentHeight: Theme.itemSizeSmall
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("VaccineDetails.qml"), {
                    vaccineId: model.id,
                    vaccineName: model.name,
                    isMandatory: model.isMandatory
                })
            }

            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr(model.name)
                color: model.isMandatory ? Theme.highlightColor : Theme.primaryColor
            }

            Icon {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                source: "image://theme/icon-m-acknowledge"
                visible: model.isMandatory
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No vaccine records")
            hintText: qsTr("Pull down to add a vaccine")
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
