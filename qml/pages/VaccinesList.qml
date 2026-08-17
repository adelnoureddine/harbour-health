import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: root
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refresh() {
        if (root.profileId >= 0) {
            DataManager.getVaccinesToModel(root.profileId, vaccineModel);
        }
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            title: qsTr("Vaccines")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add Vaccine Record")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {profileId: root.profileId})
            }
        }

        model: vaccineModel

        delegate: ListItem {
            contentHeight: Theme.itemSizeSmall
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("VaccineDetails.qml"), {
                    profileId: root.profileId,
                    vaccineId: model.id,
                    vaccineName: model.name,
                    isMandatory: model.isMandatory
                })
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
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
            enabled: vaccineModel.count === 0
            text: qsTr("No vaccine records")
            hintText: qsTr("Pull down to add a vaccine")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: vaccineModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}
// vim:et:ts=4:sw=4
