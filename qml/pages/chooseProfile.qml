import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../js/utils.js" as WtUtils


Page {
    id: root

    property bool deletingItems

    allowedOrientations: Orientation.All

    SilicaGridView {
        anchors.fill: parent
        id:gridView
        model: modelProfiles
               readonly property int columnCount: Math.floor(width/(Screen.width/2))
               cellWidth: parent.width/columnCount
               cellHeight: cellWidth

               header: PageHeader {
                   title: "Choose a profile"
               }

               ViewPlaceholder {
                   enabled: (modelProfiles.populated && modelProfiles.count === 0) || root.deletingItems
                   text: "No content"
                   hintText: "Pull down to add content"
               }
        PullDownMenu {
            id: pullDownMenu
            MenuItem {
                text: qsTr("Home")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml")) // Changer l'url pour mettre la page de l'autre groupe
            }
            MenuItem { // Si un nbrProfil = 0, ne pas afficher l'onglet information profil

                text: qsTr("Profile information")
                onClicked: pageStack.push(Qt.resolvedUrl("infosProfile.qml"))
            }

            MenuItem {
                text: qsTr("Create a profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
        }
        delegate: GridItem {

                    onClicked: {
                        if (!menuOpen && pageStack.depth == 2) {
			    WtUtils.useProfile(model.user_id);
                            pageStack.animatorPush(Qt.resolvedUrl("./infosProfile.qml"))
                        }
                    }

                    enabled: !root.deletingItems
                    opacity: enabled ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimator {}}

                    Column {
                        id: content

                        x: Theme.paddingLarge
                        y: Theme.paddingLarge
                        width: parent.width - 2 * x
                        height: parent.height - y
                        spacing: Theme.paddingMedium

                        Label {
                            width: parent.width
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            text: "User : " + model.text
                            wrapMode: Text.Wrap
                            font.capitalization: Font.Capitalize
                        }

                    }

                    OpacityRampEffect {
                        sourceItem: content
                        slope: 1
                        offset: 0
                        direction: OpacityRamp.TopToBottom
                    }
                }
                VerticalScrollDecorator {}
            }

            ListModel {
                id: modelProfiles

                }

    Component.onCompleted:{
        WtUtils.loadAllProfiles(modelProfiles)

    }
}

