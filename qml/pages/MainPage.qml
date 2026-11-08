import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager
import "../js/utils.js" as Utils
import "../components"

/*
 * The dashboard: the profile's modules as one list of cards, in the order chosen in
 * Arrange dashboard, each card loading its own data. Metrics are cards (weight wide,
 * with its trend), daily totals are goal rings, and the pages of their own
 * (conditions, vaccines, meditation, cycle) are rows saying where things stand. The
 * dashboard has no action buttons: tapping opens a card's page, and adding goes
 * through each card's long-press menu or the pull-down's "Add measurement".
 */
Page {
    id: mainPage
    // Looked up by DataTransfer after a restore, to unwind back to a clean dashboard.
    objectName: "dashboardPage"

    allowedOrientations: Orientation.All

    property int profileCount: 0
    property int profileId: -1
    property var profile
    property string todayText: ""

    /*
     * Nothing is shown until the first build is done. The page used to appear empty
     * first, so even with a profile the launch flashed "No profile yet" (and then "No
     * modules enabled") before the dashboard replaced it.
     */
    property bool loaded: false
    // False while the profile has no readings at all: shows the getting-started card.
    property bool hasReadings: true

    /*
     * builtFrom is the data the cards last showed (DataManager.dataKey): coming back
     * with nothing written does nothing at all. builtFor is the profile and the
     * enabled modules the sections were built for: when only readings changed, the
     * cards reload in place and keep the scroll position; only another profile or a
     * module switched on or off rebuilds them.
     */
    property string builtFrom: ""
    property string builtFor: ""
    property var modules: []

    // Two columns in portrait, four in landscape. A wide card takes two.
    readonly property int columns: isLandscape ? 4 : 2
    readonly property real gap: Theme.paddingMedium
    readonly property real sectionWidth: width - 2 * Theme.horizontalPageMargin
    readonly property real halfWidth: Math.floor((sectionWidth - (columns - 1) * gap) / columns)
    readonly property real fullWidth: 2 * halfWidth + gap
    // One height for every half-width card, so the cards of a row line up.
    readonly property real cardHeight: 2 * Theme.paddingLarge + Theme.iconSizeSmall
                                       + Theme.fontSizeExtraLarge * 1.3
                                       + Theme.fontSizeExtraSmall * 1.4 + Theme.paddingSmall
                                       + 2 * Theme.paddingSmall

    /*
     * Wide cards (weight, empty rows, the summary rows) take a whole row and the others
     * pair up, the two of a pair made the same height. In a free order a half card can
     * end up alone on its row; in portrait it is stretched instead of leaving a hole.
     */
    function relayout() {
        var pending = null;
        for (var i = 0; i < cardRepeater.count; i++) {
            var slot = cardRepeater.itemAt(i);
            var card = slot ? slot.item : null;
            if (!card) {
                continue;
            }
            if (card.wantsWide) {
                if (pending) {
                    pending.wide = true;
                    pending.rowHeight = 0;
                    pending = null;
                }
                card.wide = true;
                card.rowHeight = 0;
            } else {
                card.wide = false;
                if (columns === 2 && pending) {
                    var height = Math.max(pending.naturalHeight, card.naturalHeight);
                    pending.rowHeight = height;
                    card.rowHeight = height;
                    pending = null;
                } else {
                    card.rowHeight = 0;
                    pending = columns === 2 ? card : null;
                }
            }
        }
        if (pending) {
            pending.wide = true;
        }
    }

    onColumnsChanged: relayoutTimer.restart()

    // Coalesces the many changes while cards load into one pass.
    Timer {
        id: relayoutTimer
        interval: 0
        onTriggered: mainPage.relayout()
    }

    function updateData() {
        var key = DataManager.dataKey();
        if (key === builtFrom) {
            return;
        }
        todayText = Qt.formatDate(new Date(), Qt.DefaultLocaleLongDate);
        profileCount = DataManager.countProfiles();
        var id = profileCount > 0 ? DataManager.lastUsedProfileId() : -1;
        var modules = id >= 0 ? DataManager.getModules(id, true) : [];
        var ids = [];
        for (var i = 0; i < modules.length; i++) {
            ids.push(modules[i].id);
        }
        var signature = id + ":" + ids.join(",");
        profile = id >= 0 ? DataManager.getProfile(id) : undefined;
        hasReadings = id >= 0 ? DataManager.hasLogs(id) : true;

        if (signature !== builtFor) {
            // Emptied before profileId changes, so no card loads for the wrong profile.
            mainPage.modules = [];
            profileId = id;
            mainPage.modules = modules;
            builtFor = signature;
        } else {
            for (var c = 0; c < cardRepeater.count; c++) {
                var slot = cardRepeater.itemAt(c);
                if (slot && slot.item) {
                    slot.item.refresh();
                }
            }
        }
        // Recorded last, so a build that failed half way is tried again next time.
        builtFrom = key;
        loaded = true;
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            updateData();
        }
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: welcome.active ? Math.max(height, welcome.height + 4 * Theme.paddingLarge)
                                      : content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Profiles")
                visible: profileCount > 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("chooseProfile.qml"))
            }
            MenuItem {
                text: qsTr("Create a new profile")
                visible: profileCount === 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("createProfile.qml"))
            }
            MenuItem {
                text: qsTr("Backup and restore")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("DataTransfer.qml"))
            }
            MenuItem {
                text: qsTr("Cover page settings")
                visible: mainPage.profileId >= 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("coverSettings.qml"), {
                    profileId: mainPage.profileId
                })
            }
            MenuItem {
                text: qsTr("Arrange dashboard")
                visible: mainPage.profileId >= 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("moduleSettings.qml"), {
                    profileId: mainPage.profileId
                })
            }
            // Last, so it is the one closest to the finger.
            MenuItem {
                text: qsTr("Add measurement")
                visible: mainPage.profileId >= 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("pickMeasurement.qml"), {
                    profileId: mainPage.profileId
                })
            }
        }

        Column {
            id: content
            width: parent.width
            visible: mainPage.loaded && mainPage.profileCount > 0
            // Faded in once built, rather than popping in over an empty page.
            opacity: visible ? 1 : 0
            Behavior on opacity { FadeAnimation {} }

            // Profile name, today's date and an initial. Tapping it switches profile.
            BackgroundItem {
                id: header
                width: parent.width
                height: Math.max(Theme.itemSizeLarge, headerText.height + 2 * Theme.paddingLarge)
                enabled: mainPage.profileCount > 0
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("chooseProfile.qml"))

                Rectangle {
                    id: avatar
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    visible: mainPage.profile ? true : false
                    width: Theme.itemSizeSmall
                    height: width
                    radius: width / 2
                    color: Theme.rgba(Theme.highlightColor, 0.3)

                    Label {
                        anchors.centerIn: parent
                        text: mainPage.profile ? Utils.initials(mainPage.profile.firstName, "") : ""
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.highlightColor
                    }
                }

                Column {
                    id: headerText
                    anchors.right: avatar.visible ? avatar.left : parent.right
                    anchors.rightMargin: avatar.visible ? Theme.paddingLarge : Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.horizontalPageMargin - (avatar.visible ? avatar.width + Theme.paddingLarge : 0)
                           - Theme.horizontalPageMargin

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        truncationMode: TruncationMode.Fade
                        text: mainPage.profile ? mainPage.profile.firstName : qsTr("No profile selected")
                        font.pixelSize: Theme.fontSizeExtraLarge
                        font.family: Theme.fontFamilyHeading
                        color: Theme.highlightColor
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        truncationMode: TruncationMode.Fade
                        text: mainPage.todayText
                        font.pixelSize: Theme.fontSizeSmall
                        color: header.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            // A new profile has nothing but "No readings yet" cards. This says where to
            // start, and goes away with the first reading.
            Card {
                visible: !mainPage.hasReadings && mainPage.modules.length > 0
                Label {
                    width: parent.width
                    text: qsTr("Getting started")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("Pull down and choose Add measurement to log your first reading. Tap a card to see its history, long-press it for quick actions, and use Arrange dashboard to choose what is shown.")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
            }

            Item {
                width: 1
                height: Theme.paddingMedium
                visible: !mainPage.hasReadings && mainPage.modules.length > 0
            }

            Flow {
                x: Theme.horizontalPageMargin
                width: mainPage.sectionWidth
                spacing: mainPage.gap

                Repeater {
                    id: cardRepeater
                    model: mainPage.modules

                    delegate: Loader {
                        id: slot
                        property var mod: modelData

                        Component.onCompleted: {
                            var common = {
                                module: slot.mod,
                                profileId: mainPage.profileId,
                                halfWidth: Qt.binding(function () { return mainPage.halfWidth; }),
                                fullWidth: Qt.binding(function () { return mainPage.fullWidth; })
                            };
                            if (slot.mod.type === DataManager.MODULE_TYPE_SUMMARY) {
                                setSource(Qt.resolvedUrl("../components/SummaryRow.qml"), common);
                            } else if (slot.mod.type === DataManager.MODULE_TYPE_METRIC && slot.mod.grouped) {
                                setSource(Qt.resolvedUrl("../components/GoalCard.qml"), common);
                            } else {
                                common.cardHeight = Qt.binding(function () { return mainPage.cardHeight; });
                                setSource(Qt.resolvedUrl("../components/DashboardCard.qml"), common);
                            }
                            if (item) {
                                item.wantsWideChanged.connect(relayoutTimer.restart);
                                item.naturalHeightChanged.connect(relayoutTimer.restart);
                            }
                            relayoutTimer.restart();
                        }

                        // Only goal cards save anything themselves (quick add). The card
                        // already shows it, and nothing else on the dashboard depends on
                        // it, so the dashboard need not reload when shown again.
                        Connections {
                            target: slot.item
                            ignoreUnknownSignals: true
                            onSaved: {
                                mainPage.hasReadings = true;
                                mainPage.builtFrom = DataManager.dataKey();
                            }
                        }
                    }
                }
            }
        }

        /*
         * First launch, or every profile deleted: what the app is and the two ways in,
         * instead of an empty dashboard with a "No profile yet" placeholder. Created only
         * then, not on every launch with a profile.
         */
        Loader {
            id: welcome
            active: mainPage.loaded && mainPage.profileCount === 0
            width: parent.width
            y: Math.max(2 * Theme.paddingLarge, (flickable.height - height) / 2)
            sourceComponent: welcomeComponent
        }

        Component {
            id: welcomeComponent
            Column {
                width: welcome.width
                spacing: Theme.paddingLarge
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { FadeAnimation {} }

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "/usr/share/icons/hicolor/172x172/apps/harbour-health.png"
                    width: Theme.iconSizeExtraLarge
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                }

                Column {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    spacing: Theme.paddingSmall

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: qsTr("Welcome to Health")
                        font.pixelSize: Theme.fontSizeExtraLarge
                        color: Theme.highlightColor
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        text: qsTr("A private journal for your health: measurements, conditions, vaccines and more.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.secondaryHighlightColor
                    }
                }

                Card {
                    spacing: Theme.paddingMedium

                    Repeater {
                        model: [
                            { icon: "heartrate.svg", text: qsTr("Weight, blood pressure, water and more on one dashboard") },
                            { icon: "trend.svg", text: qsTr("See how each measurement changes over time") },
                            { icon: "lock.svg", text: qsTr("No account and no internet: everything stays on this phone") }
                        ]
                        delegate: Row {
                            width: parent.width
                            spacing: Theme.paddingMedium

                            HighlightImage {
                                id: featureIcon
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                sourceSize.width: Theme.iconSizeMedium
                                sourceSize.height: Theme.iconSizeMedium
                                source: Qt.resolvedUrl("../icons/" + modelData.icon)
                                color: Theme.secondaryHighlightColor
                            }
                            Label {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - featureIcon.width - parent.spacing
                                wrapMode: Text.Wrap
                                text: modelData.text
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primaryColor
                            }
                        }
                    }
                }

                // The two ways in. Creating a profile is the usual one, so it stands out;
                // restoring is for moving from another phone.
                Column {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    spacing: Theme.paddingMedium

                    Repeater {
                        model: [
                            { primary: true, icon: "profile-add.svg", page: "createProfile.qml",
                              title: qsTr("Create your profile"),
                              detail: qsTr("Your name and birthday, to get started") },
                            { primary: false, icon: "restore.svg", page: "DataTransfer.qml",
                              title: qsTr("Restore a backup"),
                              detail: qsTr("Bring back data exported from Health on another phone") }
                        ]
                        delegate: BackgroundItem {
                            id: action
                            width: parent.width
                            height: Math.max(Theme.itemSizeLarge, actionText.height + 2 * Theme.paddingLarge)
                            highlightedColor: "transparent"
                            onClicked: pageStack.animatorPush(Qt.resolvedUrl(modelData.page))

                            CardBackground {
                                anchors.fill: parent
                                highlighted: action.highlighted
                                primary: modelData.primary
                            }

                            HighlightImage {
                                id: actionIcon
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.paddingLarge
                                anchors.verticalCenter: parent.verticalCenter
                                width: Theme.iconSizeMedium
                                height: Theme.iconSizeMedium
                                sourceSize.width: Theme.iconSizeMedium
                                sourceSize.height: Theme.iconSizeMedium
                                source: Qt.resolvedUrl("../icons/" + modelData.icon)
                                color: Theme.primaryColor
                                highlighted: action.highlighted
                            }

                            Column {
                                id: actionText
                                anchors.left: actionIcon.right
                                anchors.leftMargin: Theme.paddingLarge
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.paddingLarge
                                anchors.verticalCenter: parent.verticalCenter

                                Label {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: modelData.title
                                    color: action.highlighted ? Theme.highlightColor : Theme.primaryColor
                                }
                                Label {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: modelData.detail
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    color: action.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                                }
                            }
                        }
                    }
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: qsTr("Health is not medical advice and must not be used for diagnosis or treatment decisions.")
                    font.pixelSize: Theme.fontSizeTiny
                    color: Theme.secondaryColor
                }
            }
        }

        ViewPlaceholder {
            enabled: mainPage.loaded && mainPage.profileId >= 0 && mainPage.modules.length === 0
            text: qsTr("No modules enabled")
            hintText: qsTr("Pull down and choose Arrange dashboard to pick what to track")
        }

        VerticalScrollDecorator {}
    }

    // Only if the first build takes a noticeable moment: a spinner instead of an empty
    // page. Most launches are done before it would show.
    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: !mainPage.loaded && busyDelay.elapsed && appWindow.databaseError === ""
    }

    Timer {
        id: busyDelay
        property bool elapsed: false
        interval: 500
        running: true
        onTriggered: elapsed = true
    }

    // Shown only when the database itself could not be opened or upgraded.
    Rectangle {
        anchors.fill: parent
        color: Theme.overlayBackgroundColor
        visible: appWindow.databaseError !== ""

        Column {
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.horizontalPageMargin
            spacing: Theme.paddingLarge

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
                text: qsTr("Health could not open its database")
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: appWindow.databaseError
            }
        }
    }

    // No Component.onCompleted call: the page turning Active covers startup too, and
    // the dashboard used to be built twice in a row on every launch.
}

// vim:et:ts=4:sw=4
