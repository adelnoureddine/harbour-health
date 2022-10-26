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
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem{
                text: qsTr("My Profile")
            }
        }

        // Tell SilicaFlickable the height of its content.
        contentHeight: column.height

        // Place our content in a Column.  The PageHeader is always placed at the top
        // of the page, followed by our content.
        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Health")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Health App")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }

            ButtonLayout{
                Button{
                    implicitHeight: 200
                    text: "Metrics"

                }
                Button{
                    implicitHeight: 200
                    text: "Meditation"

                }
                Button{
                    implicitHeight: 200
                    text: "Vaccines"

                }
                Button{
                    implicitHeight: 200
                    text: "Health condition"

                }
                Button{
                    implicitHeight: 200
                    text: "Nutrition"

                }
                Button{
                    implicitHeight: 200
                    text: "Menstruation"

                }
            }
        }
    }
}
