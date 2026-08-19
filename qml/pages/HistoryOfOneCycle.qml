import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils

Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string startDate
    property string endDate
    property string note

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Cycle Details")
            }

            SectionHeader {
                text: qsTr("Overview")
            }

            DetailItem {
                label: qsTr("Start Date")
                value: Utils.formatDate(startDate)
            }

            DetailItem {
                label: qsTr("End Date")
                value: endDate ? Utils.formatDate(endDate) : qsTr("Ongoing")
            }

            DetailItem {
                label: qsTr("Note")
                value: note || qsTr("None")
                visible: note !== ""
            }

            SectionHeader {
                text: qsTr("Daily Logs")
            }

            Repeater {
                model: logsModel
                delegate: Column {
                    width: parent.width
                    spacing: Theme.paddingSmall
                    
                    Separator {
                        width: parent.width
                        color: Theme.secondaryColor
                        horizontalAlignment: Qt.AlignHCenter
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * Theme.horizontalPageMargin
                        truncationMode: TruncationMode.Fade
                        text: Utils.formatDate(model.date)
                        color: Theme.highlightColor
                        font.bold: true
                    }

                    DetailItem { label: qsTr("Flow"); value: model.flow }
                    DetailItem { label: qsTr("Pain"); value: model.pain }
                    DetailItem { label: qsTr("Energy"); value: model.energy }
                    DetailItem { label: qsTr("Sleep"); value: qsTr("%1 hours").arg(Utils.formatValue(model.sleepTime, 1)) }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel {
        id: logsModel
    }

    function refresh() {
        if (profileId >= 0) {
            var logs = DataManager.getMenstrualLogs(profileId);
            logsModel.clear();
            for (var i = 0; i < logs.length; i++) {
                var log = logs[i];
                if (log.date >= startDate && (!endDate || log.date <= endDate)) {
                    logsModel.append(log);
                }
            }
        }
    }

    Component.onCompleted: refresh()
}
