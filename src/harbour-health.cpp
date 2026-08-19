/*
 * Health for SailfishOS
 * Copyright (C) 2022-2026 Adel Noureddine
 * Licensed under the GNU GPL 3 license only (GPL-3.0-only).
 */

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <QCoreApplication>
#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlEngine>
#include <QLocale>
#include <QQuickView>
#include <QScopedPointer>
#include <QTranslator>
#include <QtQml>

#include <sailfishapp.h>

#include "filewriter.h"

#ifndef APP_VERSION
#define APP_VERSION "0.0"
#endif

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    // These must match [X-Sailjail] in harbour-health.desktop. Sailjail only grants
    // write access to ~/.local/share/<OrganizationName>/<ApplicationName>, and that
    // is exactly the directory QtQuick.LocalStorage derives the database path from.
    // SailfishApp would otherwise name us after argv[0] ("harbour-health") and the
    // database would land outside the sandbox.
    //
    // Order matters: QQmlEngine resolves its offline storage path when it is
    // constructed, so this has to happen before SailfishApp::createView().
    QCoreApplication::setOrganizationName(QStringLiteral("org.noureddine"));
    QCoreApplication::setOrganizationDomain(QStringLiteral("org.noureddine"));
    QCoreApplication::setApplicationName(QStringLiteral("Health"));
    QCoreApplication::setApplicationVersion(QStringLiteral(APP_VERSION));

    // sailfishapp_i18n installs the compiled catalogues next to the QML.
    QScopedPointer<QTranslator> translator(new QTranslator);
    if (translator->load(QStringLiteral("harbour-health-") + QLocale::system().name(),
                         SailfishApp::pathTo(QStringLiteral("translations")).toLocalFile())) {
        app->installTranslator(translator.data());
    }

    qmlRegisterType<FileWriter>("harbour.health.FileWriter", 1, 0, "FileWriter");

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("appVersion"),
                                            QStringLiteral(APP_VERSION));
    view->setSource(SailfishApp::pathToMainQml());
    view->show();

    return app->exec();
}
