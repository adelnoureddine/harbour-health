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
TARGET = Interface

CONFIG += sailfishapp

SOURCES += src/Interface.cpp

DISTFILES += qml/Interface.qml \
    qml/cover/CoverPage.qml \
    qml/pages/BCG.qml \
    qml/pages/Change.qml \
    qml/pages/Coqueluche.qml \
    qml/pages/DTP.qml \
    qml/pages/Delete.qml \
    qml/pages/Edit \
    qml/pages/Edit.qml \
    qml/pages/Grippe.qml \
    qml/pages/HIB.qml \
    qml/pages/HPV.qml \
    qml/pages/HepatiteB.qml \
    qml/pages/MeningocoqueB.qml \
    qml/pages/MeningocoqueC.qml \
    qml/pages/Menu.qml \
    qml/pages/Metrics.qml \
    qml/pages/MyProfile.qml \
    qml/pages/NewProfile.qml \
    qml/pages/Pneumocoque.qml \
    qml/pages/ROR.qml \
    qml/pages/Vaccines.qml \
    qml/pages/Zona.qml \
    qml/pages/about.qml \
    qml/pages/arm.qml \
    qml/pages/calf.qml \
    qml/pages/chest.qml \
    qml/pages/height.qml \
    qml/pages/hip.qml \
    qml/pages/neck.qml \
    qml/pages/thigh.qml \
    qml/pages/weight.qml \
    rpm/Interface.changes.in \
    rpm/Interface.changes.run.in \
    rpm/Interface.spec \
    rpm/Interface.yaml \
    translations/*.ts \
    Interface.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/Interface-de.ts
