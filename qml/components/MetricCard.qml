import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

BackgroundItem {
    id: root
    
    property int profileId: -1
    property string metricName
    property string title
    property string icon
    property bool grouped: false
    property var value
    property var unit
    property var invalidateSignal

    width: parent.width
    height: Theme.itemSizeHuge

    function refreshValue() {
        print("MetricCard " + root.metricName + ": refreshValue is called for profile " + root.profileId);
        if (root.profileId >= 0) {
            if (root.grouped) {
                root.value = DataManager.getLatestDayLogValue(root.profileId, root.metricName);
                print("MetricCard " + root.metricName + ": value is now " + root.value + " for profile " + root.profileId);
            }
            else {
                root.value = DataManager.getLatestLogValue(root.profileId, root.metricName);
                print("MetricCard " + root.metricName + ": value is now " + root.value + " for profile " + root.profileId);
            }
        }
    }

    function invalidateMetric(metricName) {
        if (metricName == root.metricName) {
            refreshValue();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall
        color: highlighted ? Theme.highlightBackgroundColor : Theme.rgba(Theme.primaryColor, 0.05)
        radius: Theme.paddingMedium

        Column {
            anchors.centerIn: parent
            spacing: Theme.paddingSmall

            Icon {
                source: root.icon
                anchors.horizontalCenter: parent.horizontalCenter
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
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
                    text: root.value ? root.value : '?'
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.primaryColor
                }
                
                Label {
                    text: root.unit
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryColor
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.paddingSmall
                }
            }
        }
    }

    onClicked: {
        if (root.profileId >= 0) {
            pageStack.animatorPush(Qt.resolvedUrl("../pages/MetricDetails.qml"), {
                profileId: root.profileId,
                metricName: root.metricName,
                metricUnit: root.unit,
                invalidateSignal: root.invalidateSignal
            });
        }
    }

    onMetricNameChanged: root.unit = DataManager.getMetricUnit(root.metricName);

    onProfileIdChanged: refreshValue();

    Component.onCompleted: {
        root.invalidateSignal.connect(root.invalidateMetric);
        //root.unit = DataManager.getMetricUnit(root.metricName);
        //refreshValue();
    }
}

// vim:et:ts=4:sw=4
