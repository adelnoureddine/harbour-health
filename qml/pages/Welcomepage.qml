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
                text: qsTr("Add new Data")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AddnewData.qml"))
            }
            MenuItem {
                text: "Consult History"
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("ConsultHistory.qml"))
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
                title: qsTr("Graphical Report Consomation")
            }
            Label {
                x: Theme.horizontalPageMargin
                text: qsTr("Welcome to Nutrition Page")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraLarge
            }
        }
    }
}
