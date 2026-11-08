import QtQuick 2.0
import Sailfish.Silica 1.0

/*
 * The card surface used across the app: a dimmed tint of the ambience with a thin
 * outline, so a block of content stands out over the ambience wallpaper. A plain white
 * wash all but disappeared over a real wallpaper.
 */
Rectangle {
    // Pressed or menu open.
    property bool highlighted: false
    // A lighter, outlined surface for placeholders ("No readings yet").
    property bool subtle: false
    // Tinted with the ambience highlight: the one action a page leads with.
    property bool primary: false

    radius: Theme.paddingLarge
    color: highlighted ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                       : primary ? Theme.rgba(Theme.highlightBackgroundColor, 0.5)
                                 : Theme.rgba(Theme.highlightDimmerColor, subtle ? 0.45 : 0.72)
    border.width: Math.max(1, Math.round(Theme.pixelRatio))
    border.color: Theme.rgba(Theme.primaryColor, subtle ? 0.35 : 0.2)
}

// vim:et:ts=4:sw=4
