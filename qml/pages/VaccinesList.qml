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
        id: listView
        anchors.fill: parent

        header: PageHeader {
            width: listView.width
            title: qsTr("Vaccines")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add vaccine record")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {profileId: root.profileId})
            }
        }

        model: vaccineModel

        delegate: ListItem {
            id: vaccineItem
            contentHeight: Theme.itemSizeSmall
            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("VaccineDetails.qml"), {
                    profileId: root.profileId,
                    vaccineId: model.id,
                    vaccineName: model.name
                })
            }

            // A "mandatory" highlight used to be drawn here, but no vaccine is ever
            // marked mandatory, so it never showed.
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.name
                truncationMode: TruncationMode.Fade
                color: vaccineItem.highlighted ? Theme.highlightColor : Theme.primaryColor
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
