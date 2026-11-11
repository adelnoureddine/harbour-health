import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string profileName: ""

    // What the page last loaded (see DataManager.dataKey). It loads when created, so
    // the content is there as the page slides in, and used to load all over again
    // as soon as it became active.
    property string loadedFrom: ""

    // Also called by the window when the app comes back or the day turns.
    function reloadIfStale() {
        if (DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }

    function refresh() {
        loadedFrom = DataManager.dataKey();
        listModel.clear();
        if (profileId < 0) {
            return;
        }
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        var medications = DataManager.getMedications(profileId);
        // Medications without an intake today are not in the summary.
        var today = DataManager.getMedicationTodaySummary(profileId);
        medications.forEach(function(m) {
            var taken = today[m.id];
            listModel.append({
                id: m.id,
                name: m.name ? String(m.name) : "",
                todayCount: taken ? taken.count : 0,
                lastTimestamp: taken ? taken.last : ""
            });
        });
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        spacing: Theme.paddingMedium

        header: PageHeader {
            width: listView.width
            title: qsTr("All medications")
            description: page.profileName
        }

        footer: Item {
            width: listView.width
            height: Theme.paddingLarge
        }

        model: listModel

        // A card per medication, like the conditions list.
        delegate: ListItem {
            id: medicationItem
            width: listView.width
            contentHeight: Math.max(Theme.itemSizeMedium, medicationColumn.height + 2 * Theme.paddingLarge)
            // The card below shows the press instead of a full-width block.
            highlightedColor: "transparent"

            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultMedication.qml"), {
                profileId: page.profileId,
                medicationId: model.id,
                medicationName: model.name
            })

            CardBackground {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: parent.height
                highlighted: medicationItem.highlighted
            }

            Column {
                id: medicationColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin + Theme.paddingLarge
                width: parent.width - 2 * x

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.name
                    color: medicationItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: Utils.medicationTodayText(model.todayCount, model.lastTimestamp)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: medicationItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            // Logging a dose is the everyday action; it no longer needs a detour
            // through the medication's page. Built when first opened.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Log intake")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("LogMedicationIntake.qml"), {
                            profileId: page.profileId,
                            medicationId: model.id,
                            medicationName: model.name
                        })
                    }
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
        if (status === PageStatus.Active) {
            reloadIfStale();
        }
    }

    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
