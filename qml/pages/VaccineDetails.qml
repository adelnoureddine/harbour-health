import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int vaccineId
    property string vaccineName
    property bool isMandatory

    function refresh() {
        listModel.clear();
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var logs = DataManager.getVaccineLogs(profiles[0].id, vaccineId);
            logs.forEach(function(l) {
                listModel.append(l);
            });
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
                })
            }
        }

        model: listModel

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
            enabled: listModel.count === 0
            text: qsTr("No injections recorded")
            hintText: qsTr("Pull down to record an injection")
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
