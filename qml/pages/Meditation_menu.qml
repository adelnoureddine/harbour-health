import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: meditation_menu
    allowedOrientations: Orientation.All



    Column{
        width: page.width
        spacing: Theme.paddingLarge
        PageHeader{
            title: qsTr("Meditation")
        }

        ButtonLayout{
            Button{
                text: qsTr("test")
            }
            Button{
                text: qsTr("test")
            }
            Button{
                text: qsTr("test")
            }
        }
    }





}
