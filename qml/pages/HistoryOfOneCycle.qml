import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string startDate
    property string endDate
    property string note
    // From the cycle history (see its cycleLength): -1 while the cycle is in progress.
    property int lengthDays: -1

    property string profileName: ""
    // What the page last loaded (see DataManager.dataKey). Coming back from a
    // cancelled edit does not reload.
    property string loadedFrom: ""
    property bool loaded: false

    // A cycle opened without its length still shows one once it has an end date. An
    // unparsable date counts as 0 days, so the page reads day 1 rather than NaN.
    readonly property int shownLength: lengthDays >= 0 ? lengthDays
                                     : endDate ? (Utils.daysBetween(startDate, endDate) || 0) + 1 : -1
    readonly property int currentDay: (Utils.daysBetween(startDate, new Date()) || 0) + 1

    function refresh() {
        if (profileId >= 0) {
            var key = DataManager.dataKey();
            var profile = DataManager.getProfile(profileId);
            profileName = profile ? profile.firstName : "";
            var logs = DataManager.getMenstrualLogs(profileId);
            var rows = [];
            for (var i = 0; i < logs.length; i++) {
                var log = logs[i];
                if (log.date >= startDate && (!endDate || log.date <= endDate)) {
                    rows.push(log);
                }
            }
            logsModel.clear();
            if (rows.length > 0) {
                logsModel.append(rows);
            }
            loaded = true;
            loadedFrom = key;
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: logsModel

        header: Column {
            width: listView.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Cycle details")
                description: page.profileName
            }

            Card {
                spacing: Theme.paddingMedium

                Column {
                    width: parent.width
                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        //: Caption over a finished cycle's length
                        text: page.shownLength >= 0 ? qsTr("Length") : qsTr("In progress")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }
                    Label {
                        width: parent.width
                        truncationMode: TruncationMode.Fade
                        text: page.shownLength >= 0 ? qsTr("%n day(s)", "", page.shownLength)
                                                    : qsTr("Day %1").arg(page.currentDay)
                        font.pixelSize: Theme.fontSizeExtraLarge
                        color: Theme.primaryColor
                    }
                }

                Grid {
                    id: facts
                    width: parent.width
                    columns: 2
                    columnSpacing: Theme.paddingLarge

                    readonly property real cellWidth: (width - columnSpacing) / 2

                    Column {
                        width: facts.cellWidth
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: qsTr("Start date")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: Utils.formatDate(page.startDate)
                            color: Theme.primaryColor
                        }
                    }
                    Column {
                        width: facts.cellWidth
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: qsTr("End date")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: page.endDate ? Utils.formatDate(page.endDate) : qsTr("Ongoing")
                            color: Theme.primaryColor
                        }
                    }
                }

                Label {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: page.note ? page.note : ""
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }

            Card {
                subtle: true
                visible: page.loaded && logsModel.count === 0

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    text: qsTr("No daily data recorded during this cycle.")
                }
            }
        }

        section {
            property: "date"
            criteria: ViewSection.FullString
            // No width override: SectionHeader already spans the view minus both margins.
            delegate: SectionHeader {
                //: Heading of a day in a cycle: %1 is the day ("Yesterday", "Monday 2 November"), %2 its number in the cycle
                text: qsTr("%1 · day %2").arg(Utils.dayTitle(section))
                                         .arg((Utils.daysBetween(page.startDate, section) || 0) + 1)
            }
        }

        delegate: ListItem {
            id: logItem
            contentHeight: Math.max(Theme.itemSizeSmall, logColumn.height + 2 * Theme.paddingMedium)

            // Built when first opened, like every list menu in the app.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddTodayInfo.qml"), {
                            profileId: page.profileId,
                            logDate: Utils.fromLocalDateString(model.date)
                        })
                    }
                }
            }

            Column {
                id: logColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Flow {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Row {
                        spacing: Theme.paddingSmall
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Flow")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: logItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                        StatusPill {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Utils.flowDisplayName(model.flow)
                            dotColor: Utils.cycleLevelColor("flow", model.flow)
                        }
                    }
                    Row {
                        spacing: Theme.paddingSmall
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Pain")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: logItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                        StatusPill {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Utils.painDisplayName(model.pain)
                            dotColor: Utils.cycleLevelColor("pain", model.pain)
                        }
                    }
                    Row {
                        spacing: Theme.paddingSmall
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Energy")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: logItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                        StatusPill {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Utils.energyDisplayName(model.energy)
                            dotColor: Utils.cycleLevelColor("energy", model.energy)
                        }
                    }
                    Row {
                        spacing: Theme.paddingSmall
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Sleep")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: logItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        }
                        Label {
                            id: sleepValue
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("%1 hours").arg(Utils.formatValue(model.sleepTime, 1))
                            font.pixelSize: Theme.fontSizeSmall
                            color: logItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                    }
                }

                // The day's note was saved but never shown anywhere.
                Label {
                    width: parent.width
                    text: model.note ? model.note : ""
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Elide
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: logItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: logsModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }
}

// vim:et:ts=4:sw=4
