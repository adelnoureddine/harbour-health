import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root
    property string title: ""
    property string value: ""
    property string unit: ""
    property string icon: ""

    height: Theme.itemSizeHuge

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall
        color: Theme.rgba(Theme.highlightColor, 0.1)
        radius: Theme.paddingSmall

        Column {
            anchors.centerIn: parent
            spacing: Theme.paddingSmall
            
            Icon {
                source: root.icon
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.highlightColor
            }

            Label {
                text: root.title
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingSmall
                
                Label {
                    text: root.value
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.primaryColor
                }
                
                Label {
                    text: root.unit
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall / 2
                }
            }
        }
    }
}
