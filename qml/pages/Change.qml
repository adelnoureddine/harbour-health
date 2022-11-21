import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    SilicaListView {
        anchors.fill: parent

        model: ListModel {
            id: listModel
            Component.onCompleted: {
                for (var i=0; i<10; i++) {
                    append({"name": "Item " + i})
                }
            }
        }

        delegate: ListItem {
            width: ListView.view.width

            Label {
                id: label
                text: model.name
                anchors.centerIn: parent
            }
            menu: ContextMenu {
                MenuItem {
                    text: "Sub menu 1"
                }
                MenuItem {
                    text: "Sub menu 2"
                }
            }
        }
    }
}
