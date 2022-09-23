import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Health")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Health is a health and fitness tracker")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            SectionHeader {
                text: qsTr("Maintainer and Current Developer")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Adel Noureddine © 2022")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            SectionHeader {
                text: qsTr("Initial Authors")
            }

            Column {

                width: parent.width

                Label {
                    text: "xxx © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                Label {
                    text: "xxx © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                Label {
                    text: "xxx © 2022"
                    font.pixelSize: Theme.fontSizeSmall
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            SectionHeader {
                text: qsTr("Source Code")
            }

            Label {
                wrapMode: Text.Wrap
                x: Theme.horizontalPageMargin
                width: parent.width - ( 2 * Theme.horizontalPageMargin )
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Licensed under the GNU GPL 3 license only (GPL-3.0-only)")
                font.pixelSize: Theme.fontSizeSmall
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
            }

            Icon {
                 source: "image://theme/icon-s-cloud-download"
                 anchors {
                     horizontalCenter: parent.horizontalCenter
                 }
             }

            Text {
                text: "<a href=\"https://gitlab.com/adelnoureddine/harbour-health\">" + qsTr("View source code on GitLab") + "</a>"
                anchors {
                    horizontalCenter: parent.horizontalCenter
                }
                font.pixelSize: Theme.fontSizeSmall
                linkColor: Theme.highlightColor

                onLinkActivated: Qt.openUrlExternally("https://gitlab.com/adelnoureddine/harbour-health")
            }
        }
    }
}
