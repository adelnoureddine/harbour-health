import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int conditionId
    property string conditionName
    property var conditionData: ({})
    property string profileName: ""

    // What the page last loaded (see DataManager.dataKey). It loads when created, so
    // the content is there as the page slides in, and used to load all over again
    // as soon as it became active.
    property string loadedFrom: ""

    function refresh() {
        loadedFrom = DataManager.dataKey();
        conditionData = DataManager.getCondition(conditionId) || {};
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        listModel.clear();
        if (profileId >= 0) {
            var treatments = DataManager.getTreatments(profileId, -1, conditionId);
            treatments.forEach(function(t) {
                // Plain strings: NULL columns would change a role's type between rows.
                listModel.append({
                    id: t.id,
                    medicationId: t.medicationId,
                    medicationName: t.medicationName ? String(t.medicationName) : "",
                    dosage: t.dosage ? String(t.dosage) : "",
                    frequency: t.frequency ? String(t.frequency) : "",
                    startDate: t.startDate ? String(t.startDate) : "",
                    endDate: t.endDate ? String(t.endDate) : ""
                });
            });
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                // The stored name, so an edit made from this page shows on return.
                title: page.conditionData.name || page.conditionName
                description: page.profileName
            }

            // The condition at a glance: where it stands, when it started and ended,
            // and the notes in full.
            Card {
                spacing: Theme.paddingMedium

                StatusPill {
                    text: Utils.conditionStatusDisplayName(page.conditionData.status)
                    dotColor: Utils.conditionStatusColor(page.conditionData.status)
                }

                Row {
                    width: parent.width
                    spacing: Theme.paddingLarge

                    Column {
                        width: (parent.width - parent.spacing) / 2
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
                            //: Shown when a health condition has no start date
                            text: page.conditionData.startDate ? Utils.formatDate(page.conditionData.startDate)
                                                               : qsTr("Unknown")
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.primaryColor
                        }
                    }
                    Column {
                        width: (parent.width - parent.spacing) / 2
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
                            text: page.conditionData.endDate ? Utils.formatDate(page.conditionData.endDate)
                                                             : qsTr("Ongoing")
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.primaryColor
                        }
                    }
                }

                Label {
                    width: parent.width
                    visible: notesText.visible
                    text: qsTr("Notes")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    id: notesText
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    text: page.conditionData.note || ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
            }

            SectionHeader {
                text: qsTr("Treatments")
            }

            // A ViewPlaceholder sits a third of the way down the screen, on top of the
            // card above; this one stays under the section header.
            Card {
                subtle: true
                visible: listModel.count === 0
                spacing: 0

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("No treatments for this condition")
                    color: Theme.highlightColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Pull down to add a treatment")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryHighlightColor
                }
            }
        }

        footer: Item {
            width: listView.width
            height: Theme.paddingLarge
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Edit condition")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {
                    profileId: page.profileId,
                    conditionId: page.conditionId
                })
            }
            // Most used, so last: nearest to where the pulley stops.
            MenuItem {
                text: qsTr("Add treatment")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditMedication.qml"), {
                    profileId: page.profileId,
                    conditionId: page.conditionId
                })
            }
        }

        model: listModel

        delegate: ListItem {
            id: treatmentItem
            contentHeight: Math.max(Theme.itemSizeMedium, treatmentColumn.height + 2 * Theme.paddingMedium)

            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultMedication.qml"), {
                profileId: page.profileId,
                medicationId: model.medicationId,
                medicationName: model.medicationName
            })

            Column {
                id: treatmentColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: model.medicationName
                    color: treatmentItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    truncationMode: TruncationMode.Fade
                    text: model.frequency ? qsTr("%1 · %2").arg(model.dosage).arg(model.frequency)
                                          : model.dosage
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: treatmentItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    truncationMode: TruncationMode.Fade
                    text: Utils.periodText(model.startDate, model.endDate)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: treatmentItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            // On the row, not in the menu: the menu is destroyed as soon as it closes,
            // before the remorse runs out, and its model.id with it.
            function remove() {
                // Read now: the rows are rebuilt if anything is saved during the countdown.
                var id = model.id;
                // The intakes logged for its medication go with the last treatment using
                // it. The countdown says so; it used to say only "Deleting".
                var intakes = DataManager.countIntakesOfTreatment(id);
                function run() {
                    DataManager.deleteTreatment(id);
                    page.refresh();
                }
                if (intakes > 0) {
                    //: Countdown text when deleting a treatment whose logged intakes are deleted with it
                    treatmentItem.remorseAction(qsTr("Deleting with %n logged intake(s)", "", intakes), run);
                } else {
                    treatmentItem.remorseDelete(run);
                }
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditMedication.qml"), {
                            profileId: page.profileId,
                            conditionId: page.conditionId,
                            treatmentId: model.id
                        })
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: treatmentItem.remove()
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: listModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
