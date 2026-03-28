import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int vaccineId
    property string vaccineName
    property bool isMandatory

    function refresh() {
        if (profileId >= 0) {
            DataManager.getVaccineLogsToModel(profiles[0].id, vaccineId, vaccinesDetailModel);
        }
    }

    SilicaListView {
        anchors.fill: parent

        header: PageHeader {
            title: qsTr("%1 History").arg(vaccineName)
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Record Injection")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {
                    // In a more complex app we might pass the vaccine ID to auto-fill
		    profileId: page.profileId
                })
            }
        }

        model: vaccinesDetailModel

        delegate: ListItem {
            contentHeight: Theme.itemSizeSmall
            
            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.date
                color: Theme.primaryColor
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.note || ""
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

    Component.onCompleted: refresh()
}
