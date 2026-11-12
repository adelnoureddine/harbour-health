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

# The version shown on the About page. A package build passes the RPM's own version
# (QMakeOptions in rpm/harbour-health.yaml), so the two cannot differ; the value here
# is only for a build run by hand.
isEmpty(APP_VERSION): APP_VERSION = 2.0

# It reaches the code through a header written into the build folder (see
# src/version.h.in for why it is not a -D option).
version_header.input = $$PWD/src/version.h.in
version_header.output = $$OUT_PWD/version.h
QMAKE_SUBSTITUTES += version_header
INCLUDEPATH += $$OUT_PWD
DEPENDPATH += $$OUT_PWD

CONFIG += sailfishapp sailfishapp_i18n c++11

SOURCES += \
    src/harbour-health.cpp \
    src/filewriter.cpp

HEADERS += \
    src/filewriter.h

OTHER_FILES += \
    src/version.h.in \
    icons/harbour-health.svg \
    tools/render_app_icon.js

TRANSLATIONS += \
    translations/harbour-health.ts \
    translations/harbour-health-fr.ts \
    translations/harbour-health-sv.ts

DISTFILES += \
    qml/harbour-health.qml \
    qml/cover/CoverPage.qml \
    qml/components/BackupStore.qml \
    qml/components/ChartRangeSelector.qml \
    qml/components/CoverToday.qml \
    qml/components/ChartStats.qml \
    qml/components/MetricChart.qml \
    qml/components/Card.qml \
    qml/components/CardBackground.qml \
    qml/components/ChartCard.qml \
    qml/components/DateTimeRow.qml \
    qml/components/StatusPill.qml \
    qml/components/CoverMetric.qml \
    qml/components/DashboardCard.qml \
    qml/components/GoalCard.qml \
    qml/components/HistoryHero.qml \
    qml/components/SessionBuzz.qml \
    qml/components/SessionKeepAwake.qml \
    qml/components/Sparkline.qml \
    qml/components/SummaryRow.qml \
    qml/js/DataManager.js \
    qml/js/utils.js \
    qml/pages/AboutPage.qml \
    qml/pages/AddAndEditIllness.qml \
    qml/pages/AddAndEditMedication.qml \
    qml/pages/AddNewCycle.qml \
    qml/pages/AddTodayInfo.qml \
    qml/pages/AddVaccine.qml \
    qml/pages/AllMedications.qml \
    qml/pages/CalcMetricDetails.qml \
    qml/pages/ConsultIllness.qml \
    qml/pages/ConsultMedication.qml \
    qml/pages/DataTransfer.qml \
    qml/pages/History.qml \
    qml/pages/HistoryOfAllCycle.qml \
    qml/pages/HistoryOfOneCycle.qml \
    qml/pages/LogMedicationIntake.qml \
    qml/pages/MainHealthCondition.qml \
    qml/pages/MainPage.qml \
    qml/pages/MeditationMenu.qml \
    qml/pages/Menstruation.qml \
    qml/pages/MetricDetails.qml \
    qml/pages/MultiMetricDetails.qml \
    qml/pages/NewSession.qml \
    qml/pages/VaccineDetails.qml \
    qml/pages/VaccinesList.qml \
    qml/pages/addConstraint.qml \
    qml/pages/addEntryMetric.qml \
    qml/pages/addEntryMultiMetric.qml \
    qml/pages/chooseProfile.qml \
    qml/pages/coverSettings.qml \
    qml/pages/createProfile.qml \
    qml/pages/deleteProfile.qml \
    qml/pages/metricConstraints.qml \
    qml/pages/modifyProfile.qml \
    qml/pages/moduleSettings.qml \
    qml/pages/pickBackupFile.qml \
    qml/pages/pickMeasurement.qml \
    qml/pages/setGoal.qml \
    qml/pages/TodayPage.qml \
    qml/pages/unitSettings.qml \
    rpm/harbour-health.changes \
    rpm/harbour-health.spec \
    rpm/harbour-health.yaml \
    harbour-health.desktop \
    qml/icons/calendar-heart.png \
    qml/icons/diabetes.png \
    qml/icons/fire.png \
    qml/icons/gauge.png \
    qml/icons/heart-pulse.png \
    qml/icons/height.png \
    qml/icons/medical-bag.png \
    qml/icons/meditation.png \
    qml/icons/needle.png \
    qml/icons/scale.png \
    qml/icons/water.png \
    qml/icons/blood-pressure.svg \
    qml/icons/waist.svg \
    qml/icons/whtr.svg \
    qml/icons/weight.svg \
    qml/icons/height.svg \
    qml/icons/bmi.svg \
    qml/icons/calories.svg \
    qml/icons/water.svg \
    qml/icons/heartrate.svg \
    qml/icons/glucose.svg \
    qml/icons/condition.svg \
    qml/icons/vaccine.svg \
    qml/icons/meditation.svg \
    qml/icons/cycle.svg \
    qml/icons/cover-water.svg \
    qml/icons/lock.svg \
    qml/icons/trend.svg \
    qml/icons/profile-add.svg \
    qml/icons/restore.svg \
    qml/icons/activity.svg \
    qml/icons/today.svg \
    qml/icons/cover-today.svg

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
