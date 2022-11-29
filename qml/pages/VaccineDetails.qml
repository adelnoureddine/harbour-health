import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0

Page {
    id: vaccineDetails

    SilicaListView{
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Update")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("UpdateVaccine.qml"))
            }
            MenuItem {
                text: qsTr("Menu")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("MainPage.qml"))
            }
        }

        header: PageHeader {
            title: "Vaccines details"
        }

        model: listModel

        delegate: ListItem{

            menu: Component {
                ContextMenu {
                    MenuItem {
                        text: "Edit"
                        onClicked: pageStack.animatorPush(Qt.resolvedUrl("UpdateRecall.qml"))
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                anchors.verticalCenter: parent.verticalCenter
                text: model.text
                truncationMode: TruncationMode.Fade
                font.capitalization: Font.Capitalize
            }


        }
    }
}
