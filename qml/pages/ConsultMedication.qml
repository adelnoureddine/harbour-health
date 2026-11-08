import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int medicationId
    property string medicationName

    // The card at the top: intakes today, the latest one, and the treatment's dosage.
    property int todayCount: 0
    property string lastTimestamp: ""
    property string dosageText: ""
    // The condition the treatment belongs to, else the profile's first name.
    property string headerDescription: ""

    // What the page last loaded (see DataManager.dataKey). It loads when created, so
    // the content is there as the page slides in, and used to load all over again
    // as soon as it became active.
    property string loadedFrom: ""

    readonly property bool hasData: historyModel.count > 0

    // Today: the time alone; before that: "Yesterday", "3 days ago", then the date.
    function lastText(timestamp) {
        if (!timestamp) {
            return "";
        }
        var when = Utils.parseTimestamp(timestamp);
        var now = new Date();
        if (when !== null && when.toDateString() === now.toDateString()) {
            return Utils.formatTime(timestamp);
        }
        return Utils.relativeTime(timestamp, false);
    }

    function refreshHeader() {
        var treatments = DataManager.getTreatments(profileId, medicationId);
        var treatment = treatments.length > 0 ? treatments[0] : null;
        dosageText = treatment ? [treatment.dosage, treatment.frequency]
                                 .filter(function (part) { return part; }).join(" · ")
                               : "";
        var condition = treatment && treatment.conditionId !== null && treatment.conditionId >= 0
                        ? DataManager.getCondition(treatment.conditionId) : null;
        if (condition && condition.name) {
            headerDescription = condition.name;
        } else {
            var profile = DataManager.getProfile(profileId);
            headerDescription = profile ? profile.firstName : "";
        }
    }

    function refresh() {
        loadedFrom = DataManager.dataKey();
        refreshHeader();
        historyModel.clear();
        // Every intake, newest first, grouped by day below. Today's used to be listed
        // a second time in a section of their own.
        var history = DataManager.getMedicationLogsHistory(profileId, medicationId);
        // Today's intakes are counted from the history instead of a second query.
        // Timestamps are local, so "today" is the local day.
        var today = Utils.toLocalDateString(new Date());
        var count = 0;
        history.forEach(function(l) {
            var timestamp = String(l.timestamp);
            if (Utils.toLocalDateString(Utils.parseTimestamp(timestamp)) === today) {
                count++;
            }
            historyModel.append({
                id: l.id,
                timestamp: timestamp,
                // Both the "T" form and SQLite's "YYYY-MM-DD HH:MM:SS" start with the day.
                day: timestamp.substring(0, 10),
                note: l.note ? String(l.note) : ""
            });
        });
        todayCount = count;
        lastTimestamp = history.length > 0 ? String(history[0].timestamp) : "";
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.medicationName
                description: page.headerDescription
            }

            Card {
                visible: page.hasData
                spacing: Theme.paddingMedium

                Row {
                    width: parent.width
                    spacing: Theme.paddingLarge

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Label above the number of intakes logged today
                            text: qsTr("Taken today")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.todayCount
                            font.pixelSize: Theme.fontSizeExtraLarge
                            color: Theme.primaryColor
                        }
                    }
                    Column {
                        width: (parent.width - parent.spacing) / 2
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Label above when the latest intake was logged
                            text: qsTr("Last intake")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.lastText(page.lastTimestamp)
                            font.pixelSize: Theme.fontSizeExtraLarge
                            color: Theme.primaryColor
                        }
                    }
                }

                Label {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: page.dosageText
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }

            Item { width: 1; height: Theme.paddingSmall }
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Log intake")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("LogMedicationIntake.qml"), {
                    profileId: page.profileId,
                    medicationId: page.medicationId,
                    medicationName: page.medicationName
                })
            }
        }

        model: historyModel

        section {
            property: "day"
            criteria: ViewSection.FullString
            // No width override: SectionHeader already spans the view minus both margins.
            delegate: SectionHeader {
                text: Utils.dayTitle(section)
            }
        }

        delegate: ListItem {
            id: intakeItem
            contentHeight: noteLabel.visible
                           ? Math.max(Theme.itemSizeMedium, intakeColumn.height + 2 * Theme.paddingMedium)
                           : Theme.itemSizeSmall

            // On the row, not in the menu: the menu is destroyed as soon as it closes,
            // before the remorse runs out, and its model.id with it.
            function remove() {
                intakeItem.remorseDelete(function() {
                    DataManager.deleteMedicationLog(model.id);
                    page.refresh();
                })
            }

            // A mistaken intake could not be removed at all.
            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: intakeItem.remove()
                    }
                }
            }

            Column {
                id: intakeColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    // The day is in the section header above.
                    text: Utils.formatTime(model.timestamp)
                    color: intakeItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    id: noteLabel
                    width: parent.width
                    text: model.note
                    visible: text !== ""
                    // Two lines before eliding.
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Elide
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: intakeItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: !page.hasData
            text: qsTr("No intakes logged")
            hintText: qsTr("Pull down to log an intake")
        }

        VerticalScrollDecorator {}
    }

    ListModel { id: historyModel }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) refresh();
    }

    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
