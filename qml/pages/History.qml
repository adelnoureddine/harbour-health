import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Page {
    id: page
    allowedOrientations: Orientation.All

    function refresh() {
        var profiles = DataManager.getProfiles();
        if (profiles.length > 0) {
            var sessions = DataManager.getMeditationSessions(profiles[0].id);
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
            title: qsTr("Meditation History")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Clear History")
                onClicked: {
                    var profiles = DataManager.getProfiles();
                    if (profiles.length > 0) {
                        DataManager.deleteMeditationHistory(profiles[0].id);
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
