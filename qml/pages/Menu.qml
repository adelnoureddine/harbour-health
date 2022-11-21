import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    // To enable PullDownMenu, place our content in a SilicaFlickable
    SilicaFlickable {
        anchors.fill: parent

        // PullDownMenu and PushUpMenu must be declared in SilicaFlickable, SilicaListView or SilicaGridView
        PullDownMenu {
            MenuItem {
                text: qsTr("My Profile")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MyProfile.qml"))
            }
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("about.qml"))
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.


            ButtonLayout {
                Button {
                    text: "Metrics"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Metrics.qml"))
                }
                Button {
                    text: "Meditation"
                }
                Button {
                    text: "Vaccines"
                    onClicked: pageStack.animatorPush(Qt.resolvedUrl("Vaccines.qml"))
                }
                Button {
                    text: "Health condition"
                }
                Button {
                    text: "Nutrition"
                }
                Button {
                    text: "Menstruation"
                }
            }

    }
}
