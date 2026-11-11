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

    /*
     * In a light ambience the same tint darkened the wallpaper under dark text: the
     * titles (highlight colour) and the secondary text had under 3:1 against the card,
     * under 2:1 over a coloured part of the wallpaper. There the card is a nearly opaque
     * white wash with a little of the tint, which keeps them above 4.5:1 wherever the
     * card lies.
     *
     * Nearly opaque on purpose: this Qt draws a see-through fill darker than its colour
     * (the colour is multiplied by its alpha twice before it is laid over what is
     * behind), so a light colour at 60 % comes out a mid grey.
     */
    readonly property bool lightAmbience: Theme.colorScheme === Theme.DarkOnLight

    radius: Theme.paddingLarge
    color: highlighted ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
         : primary ? Theme.rgba(Theme.highlightBackgroundColor, 0.5)
         : lightAmbience ? Qt.tint(Qt.rgba(1, 1, 1, 0.88), Theme.rgba(Theme.highlightDimmerColor, subtle ? 0.06 : 0.2))
                         : Theme.rgba(Theme.highlightDimmerColor, subtle ? 0.45 : 0.72)
    border.width: Math.max(1, Math.round(Theme.pixelRatio))
    border.color: Theme.rgba(Theme.primaryColor, subtle ? 0.35 : 0.2)
}

// vim:et:ts=4:sw=4
