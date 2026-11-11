import QtQuick 2.0
import QtFeedback 5.0

/*
 * A vibration to say a meditation target was reached: with eyes closed or the phone
 * face down, the ring turning green went unseen.
 *
 * Loaded through a Loader by the session page, so the page still works should the
 * QtFeedback module be missing or the phone have no vibrator.
 */
Item {
    function buzz() {
        effect.start();
    }

    HapticsEffect {
        id: effect
        attackIntensity: 0.0
        attackTime: 150
        intensity: 1.0
        duration: 900
        fadeTime: 150
        fadeIntensity: 0.0
    }
}
