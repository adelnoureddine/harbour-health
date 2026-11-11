import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

/*
 * The units values are shown and typed in: kilograms or pounds, centimetres or inches,
 * litres or fluid ounces, mg/dL or mmol/L.
 *
 * Nothing stored changes with them (see the units section of DataManager.js): a choice
 * here only converts what is on screen, so it can be changed back and forth freely. It
 * is the app's, for every profile, and kept in the app's settings rather than in the
 * database or its backups.
 */
Page {
    id: page
    allowedOrientations: Orientation.All

    // Set once the boxes show the current choice: filling them in is not a change.
    property bool ready: false

    readonly property var quantities: [
        //: Units page: what is measured in kilograms or pounds
        { key: "mass", label: qsTr("Weight") },
        //: Units page: what is measured in centimetres or inches
        { key: "length", label: qsTr("Height and waist") },
        //: Units page: what is measured in litres or fluid ounces
        { key: "volume", label: qsTr("Water") },
        //: Units page: what is measured in mg/dL or mmol/L
        { key: "glucose", label: qsTr("Glucose") }
    ]

    function unitName(unit) {
        switch (unit) {
        case "kg":     return qsTr("Kilograms (kg)");
        case "lb":     return qsTr("Pounds (lb)");
        case "cm":     return qsTr("Centimetres (cm)");
        case "in":     return qsTr("Inches (in)");
        case "L":      return qsTr("Litres (L)");
        case "fl oz":  return qsTr("US fluid ounces (fl oz)");
        default:       return unit;       // mg/dL, mmol/L
        }
    }

    function choose(quantity, unit) {
        var choices = DataManager.units();
        choices[quantity] = unit;
        // Saved at once; every page reloads its values when it is shown again.
        appWindow.setUnits(choices);
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Units")
                //: Under the Units page title: the choice applies to every profile
                description: qsTr("All profiles")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("How values are shown and typed. Your data stays as it was recorded: changing a unit only converts what is on screen, and can be changed back at any time.")
            }

            Repeater {
                model: page.quantities

                ComboBox {
                    id: box
                    readonly property string quantity: modelData.key
                    readonly property var choices: DataManager.UNIT_CHOICES[modelData.key]

                    width: column.width
                    label: modelData.label
                    menu: ContextMenu {
                        Repeater {
                            model: box.choices
                            MenuItem {
                                text: page.unitName(modelData)
                            }
                        }
                    }
                    onCurrentIndexChanged: {
                        if (page.ready && currentIndex >= 0) {
                            page.choose(quantity, choices[currentIndex]);
                        }
                    }
                    Component.onCompleted: currentIndex = Math.max(0, choices.indexOf(DataManager.units()[quantity]))
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: qsTr("Backups and CSV files always use kilograms, centimetres, litres and mg/dL, whatever is chosen here.")
            }
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: ready = true
}

// vim:et:ts=4:sw=4
