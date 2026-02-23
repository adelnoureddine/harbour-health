import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0
import "../utils.js" as WtUtils

Page {
    id: root

    property string user_firstname;
    property string user_lastname;
    property string user_gender;
    property string user_birthday;


    property string user_id;
    property Page previousPageID;

    function load(){
	user_id = WtUtils.lastUsedProfile();
	var profile = WtUtils.getProfile(user_id);
	user_firstname = profile.firstname;
	user_secondname = profile.secondname;
	user_gender = profile.gender;
	user_birthday = profile.birthday;
    }

    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Show profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
            MenuItem {
                text: qsTr("Change profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("modifyProfile.qml"))
            }
            MenuItem {
                text: qsTr("Delete profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("deleteProfile.qml"))
            }
        }

        contentHeight: column.height

        Column {
            id: column
            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Profile information")
            }
            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2
                    text: qsTr(" First Name : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_firstname
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }

            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2
                    text: qsTr(" Last Name : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_lastname
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }

            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2

                    text: qsTr(" Gender : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_gender
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }

            Row{
                Label {
                    x: Theme.horizontalPageMargin
                    width: page.width/2

                    text: qsTr(" Birthday : ")
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
                Label {
                    width: page.width/2
                    x: Theme.horizontalPageMargin
                    text: user_birthday
                    color: Theme.secondaryHighlightColor
                    font.pixelSize: Theme.fontSizeExtraLarge
                }
            }
        }
        Component.onCompleted:{
	    load();
        }
    }
}
