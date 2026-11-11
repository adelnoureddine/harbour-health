import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string profileName: ""
    // What the page last loaded (see DataManager.dataKey).
    property string loadedFrom: ""
    // Keeps the placeholder from flashing while the page is pushed.
    property bool loaded: false

    function refresh() {
        var key = DataManager.dataKey();
        listModel.clear();
        if (profileId < 0) {
            return;
        }
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        var sessions = DataManager.getMeditationSessions(profileId);
        var rows = [];
        for (var i = 0; i < sessions.length; i++) {
            var s = sessions[i];
            // The local day the session belongs to, for the section headers.
            var when = Utils.parseTimestamp(s.date);
            rows.push({ id: s.id, date: String(s.date), duration: s.duration ? s.duration : 0,
                        name: s.name ? s.name : "", day: when !== null ? Utils.toLocalDateString(when) : "" });
        }
        if (rows.length > 0) {
            listModel.append(rows);
        }
        loaded = true;
        loadedFrom = key;
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: PageHeader {
            width: listView.width
            title: qsTr("Meditation history")
            description: page.profileName
        }

        PullDownMenu {
            // Nothing to clear on an empty list.
            visible: listModel.count > 0
            MenuItem {
                text: qsTr("Clear history")
                // Wiping every session used to happen on a single tap, with no undo.
                onClicked: clearRemorse.execute(qsTr("Clearing history"), function() {
                    if (page.profileId >= 0) {
                        DataManager.deleteMeditationHistory(page.profileId);
                        page.refresh();
                    }
                })
            }
        }

        section {
            property: "day"
            criteria: ViewSection.FullString
            // No width override: SectionHeader already spans the view minus both margins.
            delegate: SectionHeader {
                text: Utils.dayTitle(section)
            }
        }

        delegate: ListItem {
            id: sessionItem
            contentHeight: Theme.itemSizeMedium

            // On the row, not in the menu: the menu is destroyed as soon as it closes,
            // before the remorse runs out, and its model.id with it.
            function remove() {
                // Read now: the row may have moved or gone by the time the countdown ends.
                var id = model.id;
                sessionItem.remorseDelete(function() {
                    DataManager.deleteMeditationSession(id);
                    page.refresh();
                })
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: sessionItem.remove()
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin - timeLabel.width - Theme.paddingMedium

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: Utils.formatDuration(model.duration)
                    color: sessionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.name !== "" ? model.name : qsTr("Meditation session")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: sessionItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            Label {
                id: timeLabel
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                // The day is in the section header above.
                text: Utils.formatTime(model.date)
                font.pixelSize: Theme.fontSizeExtraSmall
                color: sessionItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }
        }

        ViewPlaceholder {
            enabled: page.loaded && listModel.count === 0
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
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
