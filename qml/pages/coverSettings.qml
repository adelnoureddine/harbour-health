import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * The two metrics on the cover, with a preview drawn by the cover's own CoverMetric
 * at the cover's size. Each choice is saved as soon as it is picked.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    property int profileId: -1
    property string metric1: DataManager.METRIC_WEIGHT
    property string metric2: DataManager.METRIC_WATER
    property string profileName: ""
    readonly property bool waterShown: metric1 === DataManager.METRIC_WATER
                                       || metric2 === DataManager.METRIC_WATER

    // Elsewhere the blood pressure halves sit side by side as "Systolic" and
    // "Diastolic"; alone in this list they have to say what they belong to.
    function choiceName(name) {
        if (name === DataManager.METRIC_BP_SYS) {
            //: Cover metric choice: the upper blood pressure value
            return qsTr("Blood pressure, systolic");
        }
        if (name === DataManager.METRIC_BP_DIA) {
            //: Cover metric choice: the lower blood pressure value
            return qsTr("Blood pressure, diastolic");
        }
        return Utils.metricDisplayName(name);
    }

    function loadMetrics() {
        var metrics = DataManager.getMetrics();
        // By the name shown: the stored English names sort in no visible order once translated.
        metrics.sort(function (a, b) {
            return page.choiceName(a.name).localeCompare(page.choiceName(b.name));
        });
        metricModel.clear();
        for (var i = 0; i < metrics.length; i++) {
            metricModel.append({ name: metrics[i].name });
        }
    }

    function indexOfMetric(name) {
        for (var i = 0; i < metricModel.count; i++) {
            if (metricModel.get(i).name === name) {
                return i;
            }
        }
        return 0;
    }

    function refresh() {
        var profile = DataManager.getProfile(profileId);
        profileName = profile ? profile.firstName : "";
        var metrics = DataManager.getCoverMetrics(profileId);
        metric1 = metrics.metric1;
        metric2 = metrics.metric2;
        // Set after the model is populated, otherwise there is nothing to select.
        metric1Combo.currentIndex = indexOfMetric(metric1);
        metric2Combo.currentIndex = indexOfMetric(metric2);
        preview1.refresh();
        preview2.refresh();
    }

    function save() {
        DataManager.updateCoverMetrics(profileId, metric1, metric2);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Cover page settings")
                description: page.profileName
            }

            SectionHeader {
                text: qsTr("Metrics to display")
            }

            ComboBox {
                id: metric1Combo
                width: parent.width
                label: qsTr("First metric")
                menu: ContextMenu {
                    Repeater {
                        model: metricModel
                        MenuItem {
                            text: page.choiceName(model.name)
                            onClicked: {
                                page.metric1 = model.name;
                                page.save();
                                preview1.refresh();
                            }
                        }
                    }
                }
            }

            ComboBox {
                id: metric2Combo
                width: parent.width
                label: qsTr("Second metric")
                menu: ContextMenu {
                    Repeater {
                        model: metricModel
                        MenuItem {
                            text: page.choiceName(model.name)
                            onClicked: {
                                page.metric2 = model.name;
                                page.save();
                                preview2.refresh();
                            }
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Preview")
            }

            Card {
                spacing: Theme.paddingMedium

                // A cover at its real size, so what fits and how it reads is what the
                // home screen will show.
                Item {
                    width: parent.width
                    height: Math.max(Theme.coverSizeLarge.height, coverColumn.height + 2 * Theme.paddingLarge)

                    CardBackground {
                        id: coverFrame
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(Theme.coverSizeLarge.width, parent.width)
                        height: parent.height
                        subtle: true
                    }

                    // Laid out as in CoverPage.qml.
                    Column {
                        id: coverColumn
                        x: coverFrame.x + Theme.paddingLarge
                        y: Theme.paddingLarge
                        width: coverFrame.width - 2 * Theme.paddingLarge
                        spacing: Theme.paddingMedium

                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            //: Cover header: the app name and the profile's first name
                            text: page.profileName !== "" ? qsTr("Health · %1").arg(page.profileName) : qsTr("Health")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.highlightColor
                        }

                        CoverMetric {
                            id: preview1
                            width: parent.width
                            profileId: page.profileId
                            metricName: page.metric1
                        }

                        CoverMetric {
                            id: preview2
                            width: parent.width
                            profileId: page.profileId
                            metricName: page.metric2
                        }
                    }
                }

                Label {
                    width: parent.width
                    visible: page.metric1 === page.metric2
                    wrapMode: Text.Wrap
                    text: qsTr("Both slots show the same metric.")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }

                Label {
                    width: parent.width
                    visible: page.waterShown
                    wrapMode: Text.Wrap
                    //: %1 is an amount in millilitres
                    text: qsTr("With water on the cover, a cover action adds %1 ml without opening the app.").arg(250)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }
            }
        }

        VerticalScrollDecorator {}
    }

    ListModel { id: metricModel }

    Component.onCompleted: {
        loadMetrics();
        refresh();
    }
}

// vim:et:ts=4:sw=4
