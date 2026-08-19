import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1

    function refresh() {
        listModel.clear();
        if (profileId < 0) {
            return;
        }
        var sessions = DataManager.getMeditationSessions(profileId);
        for (var i = 0; i < sessions.length; i++) {
            listModel.append(sessions[i]);
        }
    }

    function formatDuration(seconds) {
        if (seconds === null || seconds === undefined) {
            return "";
        }
        if (seconds < 60) {
            return qsTr("%1 s").arg(seconds);
        }
        var minutes = Math.floor(seconds / 60);
        var remainder = seconds % 60;
        return remainder === 0 ? qsTr("%1 min").arg(minutes)
                               : qsTr("%1 min %2 s").arg(minutes).arg(remainder);
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: PageHeader {
            width: listView.width
            title: qsTr("Meditation History")
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Clear History")
                // Wiping every session used to happen on a single tap, with no undo.
                onClicked: clearRemorse.execute(qsTr("Clearing history"), function() {
                    if (page.profileId >= 0) {
                        DataManager.deleteMeditationHistory(page.profileId);
                        page.refresh();
                    }
                })
            }
        }

        delegate: ListItem {
            id: sessionItem
            contentHeight: Theme.itemSizeMedium

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Delete")
                    onClicked: sessionItem.remorseDelete(function() {
                        DataManager.deleteMeditationSession(model.id);
                        listModel.remove(index);
                    })
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    text: model.name ? model.name : qsTr("Meditation Session")
                    truncationMode: TruncationMode.Fade
                    color: sessionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: Utils.formatDateTime(model.date) + " · " + page.formatDuration(model.duration)
                    font.pixelSize: Theme.fontSizeSmall
                    color: sessionItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No meditation history")
            hintText: qsTr("Finish a session to see it here")
        }

        VerticalScrollDecorator {}
    }

    RemorsePopup { id: clearRemorse }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
