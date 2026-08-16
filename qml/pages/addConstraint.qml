import QtQuick 2.0
import Sailfish.Silica 1.0
import "../js/DataManager.js" as DataManager

Dialog {
    id: dialog
    allowedOrientations: Orientation.All

    property string metricName: ""
    property var invalidate

    canAccept: labelField.text !== "" && (minField.text !== "" || maxField.text !== "") &&
               (minField.text === "" || maxField.text === "" || parseFloat(minField.text.replace(',', '.')) < parseFloat(maxField.text.replace(',', '.')))

    onAccepted: {
        var min = (minField.text !== "" && minField.text !== null) ? parseFloat(minField.text.replace(',', '.')) : null;
        var max = (maxField.text !== "" && maxField.text !== null) ? parseFloat(maxField.text.replace(',', '.')) : null;
        var colors = ["green", "orange", "red", "blue"];
        DataManager.addConstraint(metricName, labelField.text, min, max, colors[colorCombo.currentIndex]);
        if (invalidate) invalidate();
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                title: qsTr("Add Constraint — %1").arg(metricName)
                acceptText: qsTr("Save")
            }

            TextField {
                id: labelField
                width: parent.width
                label: qsTr("Label")
                placeholderText: qsTr("e.g. Normal, Overweight, Danger...")
                focus: true
            }

            SectionHeader {
                text: qsTr("Value range")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                text: qsTr("Fill one or both fields:\n• Both → range (e.g. Normal between 18.5 and 25)\n• Minimum only → value is too low below this\n• Maximum only → value is too high above this")
            }

            TextField {
                id: minField
                width: parent.width
                label: qsTr("Minimum value (optional)")
                placeholderText: qsTr("Value must be greater than this threshold")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
            }

            TextField {
                id: maxField
                width: parent.width
                label: qsTr("Maximum value (optional)")
                placeholderText: qsTr("Value must be less than this threshold")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: RegExpValidator { regExp: /^\d+([\.|,]\d{1,2})?$/ }
            }

            ComboBox {
                id: colorCombo
                width: parent.width
                label: qsTr("Color")
                menu: ContextMenu {
                    MenuItem { text: qsTr("🟢 Green (normal)") }
                    MenuItem { text: qsTr("🟠 Orange (borderline)") }
                    MenuItem { text: qsTr("🔴 Red (too high)") }
                    MenuItem { text: qsTr("🔵 Blue (too low)") }
                }
            }
        }
    }
}
