import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

/*
 * Today: everything with a target for the day, what is still to do first. Each daily
 * total against its goal (water, calories eaten, calories burned), the meditation goal
 * once one is set, and the medications the profile is on. Opened from its dashboard row
 * and from the cover. Only modules switched on in Arrange dashboard take part.
 */
Page {
    id: page
    // Looked up by the cover, so its Today action does not open a second one.
    objectName: "todayPage"
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string profileName: ""
    // Items still open. Not "left": that is every Item's anchor line, and final.
    property int openCount: 0
    property bool loaded: false
    // What the page last loaded (see DataManager.dataKey).
    property string loadedFrom: ""

    function refresh() {
        loadedFrom = DataManager.dataKey();
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        var plan = profileId >= 0 ? DataManager.getTodayPlan(profileId) : { items: [], left: 0 };
        openCount = plan.left;
        // Every row carries every role, so each role keeps one type in the model.
        var rows = plan.items.map(function (item) {
            // A goal met several days running says so: "1.2 of 2 L · 5 days in a row".
            // Worked out here, on this page only; the dashboard row and the cover use
            // the same plan without it.
            var streak = item.kind === "medication" ? 0
                       : DataManager.getGoalStreak(profileId, item.metricName, item.goal);
            return {
                kind: item.kind,
                metricName: item.metricName ? item.metricName : "",
                unit: item.unit ? item.unit : "",
                medicationId: item.medicationId !== undefined ? item.medicationId : -1,
                title: Utils.todayItemTitle(item),
                progress: Utils.todayItemProgress(item) + (streak >= 2 ? " · " + Utils.streakText(streak) : ""),
                leftText: Utils.todayItemLeft(item),
                fraction: Utils.todayItemFraction(item),
                done: item.done ? true : false
            };
        });
        listModel.clear();
        if (rows.length > 0) {
            listModel.append(rows);
        }
        loaded = true;
    }

    function openItem(item) {
        if (item.kind === "goal") {
            pageStack.animatorPush(Qt.resolvedUrl("MetricDetails.qml"), {
                profileId: page.profileId,
                grouped: true,
                metricName: item.metricName,
                metricUnit: item.unit
            });
        } else if (item.kind === "meditation") {
            pageStack.animatorPush(Qt.resolvedUrl("MeditationMenu.qml"), { profileId: page.profileId });
        } else {
            pageStack.animatorPush(Qt.resolvedUrl("LogMedicationIntake.qml"), {
                profileId: page.profileId,
                medicationId: item.medicationId,
                medicationName: item.title
            });
        }
    }

    function openGoal(item) {
        pageStack.animatorPush(Qt.resolvedUrl("setGoal.qml"), {
            profileId: page.profileId,
            metricName: item.metricName,
            metricUnit: item.kind === "meditation" ? qsTr("min") : item.unit
        });
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: listModel

        header: Column {
            width: listView.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: qsTr("Today")
                description: page.profileName
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                visible: listModel.count > 0
                wrapMode: Text.Wrap
                //: Things still to do today, at the top of the Today page
                text: page.openCount > 0 ? qsTr("%n left for today", "", page.openCount) : qsTr("All done for today")
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        section {
            property: "done"
            delegate: SectionHeader {
                //: Today page sections: what is still open, and what is done
                text: section === "true" ? qsTr("Done") : qsTr("To do")
            }
        }

        delegate: ListItem {
            id: row
            contentHeight: Math.max(Theme.itemSizeMedium, rowColumn.height + 2 * Theme.paddingMedium)

            onClicked: page.openItem(model)

            menu: Component {
                ContextMenu {
                    MenuItem {
                        visible: model.kind === "goal"
                        text: qsTr("Add entry")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("addEntryMetric.qml"), {
                            profileId: page.profileId,
                            metricName: model.metricName,
                            metricUnit: model.unit,
                            lockMetric: true
                        })
                    }
                    MenuItem {
                        visible: model.kind === "meditation"
                        text: qsTr("New session")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("NewSession.qml"), {
                            profileId: page.profileId
                        })
                    }
                    MenuItem {
                        visible: model.kind === "medication"
                        text: qsTr("Log intake")
                        onClicked: page.openItem(model)
                    }
                    MenuItem {
                        visible: model.kind !== "medication"
                        text: qsTr("Daily goal")
                        onClicked: page.openGoal(model)
                    }
                }
            }

            // How far along: a full ring once done; a medication is either.
            ProgressCircle {
                id: ring
                anchors.left: parent.left
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSizeMedium
                height: width
                value: model.fraction
                progressColor: model.done ? Theme.secondaryHighlightColor : Theme.highlightColor
                backgroundColor: Theme.rgba(Theme.primaryColor, 0.2)
            }

            Column {
                id: rowColumn
                anchors.left: ring.right
                anchors.leftMargin: Theme.paddingLarge
                anchors.right: leftLabel.left
                anchors.rightMargin: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.title
                    color: row.highlighted ? Theme.highlightColor
                                           : (model.done ? Theme.secondaryColor : Theme.primaryColor)
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.progress
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: row.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            Label {
                id: leftLabel
                anchors.right: parent.right
                anchors.rightMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, row.width / 3)
                horizontalAlignment: Text.AlignRight
                truncationMode: TruncationMode.Fade
                text: model.leftText
                font.pixelSize: Theme.fontSizeSmall
                color: model.done ? Theme.secondaryColor : Theme.highlightColor
            }
        }

        ViewPlaceholder {
            enabled: page.loaded && listModel.count === 0
            text: qsTr("Nothing to track today")
            hintText: qsTr("Daily goals for water, calories eaten and burned, a meditation goal and the medications you are on show up here")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    // Also called by the window when the app comes back or the day turns.
    function reloadIfStale() {
        if (DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            reloadIfStale();
        }
    }

    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
