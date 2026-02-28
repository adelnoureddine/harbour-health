import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    function refresh() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var profileId = profiles[0].id;
            var cycles = DataManager.getMenstrualCycles(profileId);
            listModel.clear();
            for (var i = 0; i < cycles.length; i++) {
                listModel.append(cycles[i]);
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: PageHeader {
            title: qsTr("Cycle History")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Refresh")
                onClicked: refresh()
            }
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                
                Label {
                    text: qsTr("Started on %1").arg(model.startDate)
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    text: model.note || qsTr("No notes")
                    font.pixelSize: Theme.fontSizeSmall
                    color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    visible: model.note !== null
                }
            }

            onClicked: pageStack.animatorPush(Qt.resolvedUrl("HistoryOfOneCycle.qml"), {
                "startDate": model.startDate,
                "endDate": model.endDate,
                "note": model.note
            })
        }

        VerticalScrollDecorator {}

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No cycles recorded")
        }
    }

    ListModel {
        id: listModel
    }

    Component.onCompleted: refresh()
}
