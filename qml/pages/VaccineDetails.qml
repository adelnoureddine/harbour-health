import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property int vaccineId: -1
    property string vaccineName
    property string profileName: ""
    // The newest injection's date; the list is sorted newest first.
    property string lastDate: ""

    // What the page last loaded (see DataManager.dataKey). This page used to reload
    // every time it became active, even back from a cancelled dialog.
    property string loadedFrom: ""

    readonly property bool hasData: vaccinesDetailModel.count > 0

    function refresh() {
        loadedFrom = DataManager.dataKey();
        if (profileId >= 0) {
            var profile = DataManager.getProfile(profileId);
            profileName = profile ? profile.firstName : "";
            DataManager.getVaccineLogsToModel(profileId, vaccineId, vaccinesDetailModel);
        }
        lastDate = vaccinesDetailModel.count > 0 ? String(vaccinesDetailModel.get(0).date) : "";
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        header: Column {
            width: listView.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: page.vaccineName
                description: page.profileName
            }

            Card {
                visible: page.hasData

                Row {
                    width: parent.width
                    spacing: Theme.paddingLarge

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Number of injections of a vaccine, above the number
                            text: qsTr("Doses")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: vaccinesDetailModel.count
                            font.pixelSize: Theme.fontSizeExtraLarge
                            color: Theme.primaryColor
                        }
                    }
                    Column {
                        width: (parent.width - parent.spacing) / 2
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Label above the date of the latest injection of a vaccine
                            text: qsTr("Last injection")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: Utils.formatDate(page.lastDate)
                            font.pixelSize: Theme.fontSizeExtraLarge
                            color: Theme.primaryColor
                        }
                    }
                }
            }

            SectionHeader {
                visible: page.hasData
                text: qsTr("Injections")
            }
        }

        footer: Item {
            width: listView.width
            height: Theme.paddingLarge
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Record injection")
                // The vaccine is already known here; this used to open a blank form
                // and make the user retype the name they had just tapped.
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {
                    profileId: page.profileId,
                    knownVaccineId: page.vaccineId,
                    knownVaccineName: page.vaccineName
                })
            }
        }

        model: vaccinesDetailModel

        delegate: ListItem {
            id: injectionItem
            contentHeight: noteLabel.visible
                           ? Math.max(Theme.itemSizeMedium, injectionColumn.height + 2 * Theme.paddingMedium)
                           : Theme.itemSizeSmall

            // On the row, not in the menu: the menu is destroyed as soon as it closes,
            // before the remorse runs out, and its model.id with it.
            function remove() {
                // Read now: the rows are rebuilt if anything is saved during the countdown.
                var id = model.id;
                injectionItem.remorseDelete(function() {
                    DataManager.deleteVaccineLog(id);
                    // Reloads rather than removing the row, so the card above
                    // counts it too.
                    page.refresh();
                })
            }

            // Built when first opened. Created with every row, the menu made each
            // row about ten times slower to build, which showed while scrolling.
            menu: Component {
                ContextMenu {
                    // A wrong date or note could only be fixed by deleting the injection.
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {
                            profileId: page.profileId,
                            knownVaccineId: page.vaccineId,
                            knownVaccineName: page.vaccineName,
                            injectionId: model.id
                        })
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: injectionItem.remove()
                    }
                }
            }

            Column {
                id: injectionColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: Utils.formatDate(model.date)
                    color: injectionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    id: noteLabel
                    width: parent.width
                    text: model.note ? model.note : ""
                    visible: text !== ""
                    // Two lines before eliding: the note used to share one line with
                    // the date and was cut after a few words.
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Elide
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: injectionItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: !page.hasData
            text: qsTr("No injections recorded")
            hintText: qsTr("Pull down to record an injection")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: vaccinesDetailModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
