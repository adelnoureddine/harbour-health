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
        vaccineModel.clear();
        if (root.profileId < 0) {
            return;
        }
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        var vaccines = DataManager.getVaccineSummaries(root.profileId);
        if (vaccines.length > 0) {
            vaccineModel.append(vaccines);
        }
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        spacing: Theme.paddingMedium

        header: PageHeader {
            width: listView.width
            title: qsTr("Vaccines")
            description: root.profileName
        }

        footer: Item {
            width: listView.width
            height: Theme.paddingLarge
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Add vaccine record")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {profileId: root.profileId})
            }
        }

        model: vaccineModel

        // A card per vaccine, like the dashboard's rows. A "mandatory" highlight used
        // to be drawn here, but no vaccine is ever marked mandatory, so it never showed.
        delegate: ListItem {
            id: vaccineItem
            width: listView.width
            contentHeight: Math.max(Theme.itemSizeMedium, vaccineColumn.height + 2 * Theme.paddingLarge)
            // The card below shows the press instead of a full-width block.
            highlightedColor: "transparent"

            onClicked: {
                pageStack.animatorPush(Qt.resolvedUrl("VaccineDetails.qml"), {
                    profileId: root.profileId,
                    vaccineId: model.id,
                    vaccineName: model.name
                })
            }

            CardBackground {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                height: parent.height
                highlighted: vaccineItem.highlighted
            }

            Column {
                id: vaccineColumn
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin + Theme.paddingLarge
                width: parent.width - 2 * x
                spacing: Theme.paddingSmall

                Item {
                    width: parent.width
                    height: Math.max(nameLabel.height, dosesPill.height)

                    Label {
                        id: nameLabel
                        anchors.left: parent.left
                        anchors.right: dosesPill.visible ? dosesPill.left : parent.right
                        anchors.rightMargin: dosesPill.visible ? Theme.paddingMedium : 0
                        anchors.verticalCenter: parent.verticalCenter
                        truncationMode: TruncationMode.Fade
                        text: model.name
                        color: vaccineItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                    StatusPill {
                        id: dosesPill
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        //: Number of injections recorded for a vaccine
                        text: model.doses > 0 ? qsTr("%n dose(s)", "", model.doses) : ""
                    }
                }

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    //: %1 is the date of the latest injection of a vaccine
                    text: model.lastDate !== "" ? qsTr("Last injection on %1").arg(Utils.formatDate(model.lastDate))
                                                : qsTr("Nothing recorded yet")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: vaccineItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            // Another dose without opening the vaccine first. Built when first opened.
            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: qsTr("Record injection")
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddVaccine.qml"), {
                            profileId: root.profileId,
                            knownVaccineId: model.id,
                            knownVaccineName: model.name
                        })
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: vaccineModel.count === 0
            text: qsTr("No vaccine records")
            hintText: qsTr("Pull down to add a vaccine")
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: vaccineModel
    }

    onStatusChanged: {
        if (status === PageStatus.Active && DataManager.dataKey() !== loadedFrom) {
            refresh();
        }
    }

    Component.onCompleted: refresh()
}

// vim:et:ts=4:sw=4
