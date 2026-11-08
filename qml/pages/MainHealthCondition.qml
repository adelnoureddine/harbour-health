import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: root
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string profileName: ""

    // What the page last loaded (see DataManager.dataKey). It loads when created, so
    // the content is there as the page slides in, and used to load all over again
    // as soon as it became active.
    property string loadedFrom: ""

    function refresh() {
        loadedFrom = DataManager.dataKey();
        listModel.clear();
        if (profileId < 0) {
            return;
        }
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";

        // One query for every treatment of the profile, counted per condition, instead
        // of one per row.
        var treatmentCounts = {};
        DataManager.getTreatments(profileId).forEach(function(t) {
            treatmentCounts[t.conditionId] = (treatmentCounts[t.conditionId] || 0) + 1;
        });

        // Plain strings and numbers: a NULL end date would otherwise give the role a
        // different type from one row to the next.
        DataManager.getConditions(profileId).forEach(function(c) {
            listModel.append({
                id: c.id,
                name: c.name ? String(c.name) : "",
                status: c.status ? String(c.status) : "",
                startDate: c.startDate ? String(c.startDate) : "",
                endDate: c.endDate ? String(c.endDate) : "",
                treatmentCount: treatmentCounts[c.id] || 0
            });
        });
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        spacing: Theme.paddingMedium

        header: PageHeader {
            width: listView.width
            title: qsTr("Health conditions")
            description: root.profileName
        }

        footer: Item {
            width: listView.width
            height: Theme.paddingLarge
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("All medications")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AllMedications.qml"), {profileId: root.profileId})
            }
            // Most used, so last: nearest to where the pulley stops.
            MenuItem {
                text: qsTr("Add condition")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {profileId: root.profileId})
            }
        }

        model: listModel

        // A card per condition, like the dashboard's rows.
        delegate: ListItem {
            id: conditionItem
            width: listView.width
            contentHeight: Math.max(Theme.itemSizeMedium, conditionColumn.height + 2 * Theme.paddingLarge)
            // The card below shows the press instead of a full-width block.
            highlightedColor: "transparent"

            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("ConsultIllness.qml"), {
                    profileId: root.profileId,
                    conditionId: model.id,
                    conditionName: model.name
                })
            }

            CardBackground {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: parent.height
                highlighted: conditionItem.highlighted
            }

            Column {
                id: conditionColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin + Theme.paddingLarge
                width: parent.width - 2 * x
                spacing: Theme.paddingSmall

                Item {
                    width: parent.width
                    height: Math.max(nameLabel.height, statusPill.height)

                    Label {
                        id: nameLabel
                        anchors.left: parent.left
                        anchors.right: statusPill.left
                        anchors.rightMargin: Theme.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        truncationMode: TruncationMode.Fade
                        text: model.name
                        color: conditionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    StatusPill {
                        id: statusPill
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: Utils.conditionStatusDisplayName(model.status)
                        dotColor: Utils.conditionStatusColor(model.status)
                    }
                }

                Label {
                    width: parent.width
                    visible: text !== ""
                    truncationMode: TruncationMode.Fade
                    //: Number of treatments of a health condition, after its dates
                    text: [Utils.periodText(model.startDate, model.endDate),
                           model.treatmentCount > 0 ? qsTr("%n treatment(s)", "", model.treatmentCount) : ""]
                          .filter(function (part) { return part !== ""; }).join(" · ")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: conditionItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            // On the row, not in the menu: the menu is destroyed as soon as it closes,
            // before the remorse runs out, and its model.id with it.
            function remove() {
                conditionItem.remorseDelete(function() {
                    // Removes the condition together with its treatments.
                    DataManager.deleteCondition(model.id);
                    listModel.remove(index);
                })
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddAndEditIllness.qml"), {
                            profileId: root.profileId,
                            conditionId: model.id
                        })
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: conditionItem.remove()
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: listModel.count === 0
            text: qsTr("No health conditions recorded")
            hintText: qsTr("Pull down to add a condition")
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
