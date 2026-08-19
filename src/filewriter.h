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

/*
 * Minimal file access for data export and restore.
 *
 * QML has no API for writing files, so this is the smallest possible bridge:
 * plain text in, plain text out, confined to the directories Sailjail grants us
 * (see Permissions in harbour-health.desktop).
 */
class FileWriter : public QObject
{
    Q_OBJECT

public:
    explicit FileWriter(QObject *parent = 0);

    // ~/Documents/Health -- created on demand. Empty string if it cannot be created.
    Q_INVOKABLE QString exportDirectory();

    Q_INVOKABLE bool writeFile(const QString &path, const QString &content);
    Q_INVOKABLE QString readFile(const QString &path);

    // Files in dirPath ending in suffix, newest first. Absolute paths.
    Q_INVOKABLE QStringList listFiles(const QString &dirPath, const QString &suffix);

    // Human readable reason for the last false/empty return value.
    Q_INVOKABLE QString lastError() const;

private:
    QString m_lastError;
};

#endif // FILEWRITER_H
