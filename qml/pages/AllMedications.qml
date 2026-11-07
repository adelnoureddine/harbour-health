import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    // What the page last loaded (see DataManager.dataKey). It loads when created, so
    // the content is there as the page slides in, and used to load all over again
    // as soon as it became active.
    property string loadedFrom: ""

    function refresh() {
        loadedFrom = DataManager.dataKey();
        listModel.clear();
        var medications = DataManager.getMedications(profileId);
        medications.forEach(function(m) {
            listModel.append(m);
        });
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: PageHeader {
            width: listView.width
            title: qsTr("All medications")
        }

        model: listModel

        delegate: ListItem {
            id: medicationItem
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
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.name
                    color: medicationItem.highlighted ? Theme.highlightColor : Theme.primaryColor
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
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) refresh();
    }

    Component.onCompleted: refresh()
}
