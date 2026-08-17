import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refresh() {
        if (profileId >= 0) {
            var sessions = DataManager.getMeditationSessions(profileId);
            listModel.clear();
            for (var i = 0; i < sessions.length; i++) {
                listModel.append(sessions[i]);
            }
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: PageHeader {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * Theme.horizontalPageMargin
            title: qsTr("Meditation History")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Clear History")
                onClicked: {
                    if (profileId >= 0) {
                        DataManager.deleteMeditationHistory(profileId);
                        refresh();
                    }
                }
            }
        }

        delegate: ListItem {
            contentHeight: Theme.itemSizeMedium

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                
                Label {
                    text: model.name || qsTr("Meditation Session")
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    text: qsTr("%1 - %2 minutes").arg(model.date).arg(model.duration)
                    font.pixelSize: Theme.fontSizeSmall
                    color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No meditation history")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    Component.onCompleted: refresh()
}
