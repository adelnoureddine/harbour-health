# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-health

CONFIG += sailfishapp

SOURCES += src/harbour-health.cpp

DISTFILES += qml/harbour-health.qml \
    qml/cover/CoverPage.qml \
    qml/js/fichierUtils.js \
    qml/pages/AboutPage.qml \
    qml/pages/AddAndEditIllness.qml \
    qml/pages/AddAndEditMedication.qml \
    qml/pages/ConsultIllness.qml \
    qml/pages/ConsultMedication.qml \
    qml/pages/MainHealthCondition.qml \
    qml/pages/AddnewData \
    qml/pages/ConsultHistory.qml \
    qml/pages/MainPage.qml \
    qml/pages/Nutrition.qml \
    qml/pages/Welcomepage \
    qml/pages/chooseProfile.qml \
    qml/pages/createProfile.qml \
    qml/pages/deleteProfile.qml \
    qml/pages/infosProfile.qml \
    qml/pages/modifyProfile.qml \
    qml/pages/MetricDetails.qml \
    qml/pages/metricList.qml \
    qml/pages/addEntryMetric.qml \
    qml/utils.js \
    rpm/harbour-health.changes.in \
    rpm/harbour-health.changes.run.in \
    rpm/harbour-health.spec \
    rpm/harbour-health.yaml \
    translations/*.ts \
    harbour-health.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-health-de.ts
