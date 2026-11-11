/*
 * Health for SailfishOS
 * Copyright (C) 2022-2026 Adel Noureddine
 * Licensed under the GNU GPL 3 license only (GPL-3.0-only).
 */

#ifndef FILEWRITER_H
#define FILEWRITER_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantMap>

/*
 * Minimal file access for backups, exports and the app's own settings file.
 *
 * QML has no API for writing files, so this is the smallest possible bridge: plain
 * text in, plain text out. Writing and deleting are confined to two places, whatever
 * path QML passes: the Health folder in Documents (what the user exports and can copy
 * away) and the app's private data folder (automatic backups, settings). Reading goes
 * wherever Sailjail lets the app read (see Permissions in harbour-health.desktop), so a
 * backup picked from Downloads or a memory card can be restored.
 */
class FileWriter : public QObject
{
    Q_OBJECT

public:
    explicit FileWriter(QObject *parent = 0);

    // ~/Documents/Health -- created on demand. Empty string if it cannot be created.
    Q_INVOKABLE QString exportDirectory();

    // <private data>/backups -- created on demand. Automatic copies, which no other
    // app can read. Empty string if it cannot be created.
    Q_INVOKABLE QString backupDirectory();

    // <private data>/state.json: what the app remembers that is not health data.
    Q_INVOKABLE QString stateFile();

    Q_INVOKABLE bool writeFile(const QString &path, const QString &content);
    Q_INVOKABLE QString readFile(const QString &path);
    Q_INVOKABLE bool removeFile(const QString &path);

    // Files in dirPath ending in suffix, newest first. Absolute paths.
    Q_INVOKABLE QStringList listFiles(const QString &dirPath, const QString &suffix);

    // {exists, size, modified}: size in bytes, modified in milliseconds since the epoch.
    Q_INVOKABLE QVariantMap fileInfo(const QString &path);

    // When the database file was last written, in milliseconds since the epoch; 0
    // when there is none yet.
    Q_INVOKABLE double databaseModified();

    // Copies the database file as it is into Documents/Health, for when it cannot be
    // opened. Returns the copy's path, or an empty string.
    Q_INVOKABLE QString saveRescueCopy();

    // Human readable reason for the last false/empty return value.
    Q_INVOKABLE QString lastError() const;

private:
    QString privateDirectory();
    QString databaseFile() const;
    bool mayWrite(const QString &path);

    QString m_lastError;
};

#endif // FILEWRITER_H
