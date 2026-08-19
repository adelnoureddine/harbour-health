import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int vaccineId: -1
    property string vaccineName
    property bool isMandatory

    function refresh() {
        if (profileId >= 0) {
            DataManager.getVaccineLogsToModel(profileId, vaccineId, vaccinesDetailModel);
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: PageHeader {
            width: listView.width
            title: page.vaccineName
            description: qsTr("Injections")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Record Injection")
                // The vaccine is already known here; this used to open a blank form
                // and make the user retype the name they had just tapped.
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {
                    profileId: page.profileId,
                    knownVaccineId: page.vaccineId,
                    knownVaccineName: page.vaccineName
                })
            }
        }

        model: vaccinesDetailModel

        delegate: ListItem {
            id: injectionItem
            contentHeight: Theme.itemSizeSmall

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: injectionItem.remorseDelete(function() {
                        DataManager.deleteVaccineLog(model.id);
                        vaccinesDetailModel.remove(index);
                    })
                }
            }

            Label {
                id: dateLabel
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width / 2 - Theme.horizontalPageMargin
                truncationMode: TruncationMode.Fade
                text: Utils.formatDate(model.date)
                color: injectionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width / 2
                horizontalAlignment: Text.AlignRight
                text: model.note ? model.note : ""
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                visible: text !== ""
            }
        }

        ViewPlaceholder {
            enabled: vaccinesDetailModel.count === 0
            text: qsTr("No injections recorded")
            hintText: qsTr("Pull down to record an injection")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: vaccinesDetailModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
