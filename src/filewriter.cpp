/*
 * Health for SailfishOS
 * Copyright (C) 2022-2026 Adel Noureddine
 * Licensed under the GNU GPL 3 license only (GPL-3.0-only).
 */

#include "filewriter.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>
#include <QQmlEngine>
#include <QSaveFile>
#include <qqml.h>
#include <QStandardPaths>
#include <QTextStream>

namespace {

// A backup of years of data is a few megabytes. Anything far beyond that is not one,
// and reading it into a string would only exhaust the phone's memory.
const qint64 MaximumReadSize = 64 * 1024 * 1024;

QString ensureDirectory(const QString &parent, const QString &name)
{
    if (parent.isEmpty()) {
        return QString();
    }
    QDir dir(parent);
    if (!dir.exists(name) && !dir.mkpath(name)) {
        return QString();
    }
    return dir.filePath(name);
}

}

FileWriter::FileWriter(QObject *parent)
    : QObject(parent)
{
}

QString FileWriter::exportDirectory()
{
    m_lastError.clear();

    const QString documents = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (documents.isEmpty()) {
        m_lastError = tr("No documents folder is available.");
        return QString();
    }

    const QString directory = ensureDirectory(documents, QStringLiteral("Health"));
    if (directory.isEmpty()) {
        m_lastError = tr("Could not create %1").arg(QDir(documents).filePath(QStringLiteral("Health")));
    }
    return directory;
}

QString FileWriter::privateDirectory()
{
    const QString data = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (data.isEmpty()) {
        return QString();
    }
    if (!QDir().mkpath(data)) {
        return QString();
    }
    return data;
}

QString FileWriter::backupDirectory()
{
    m_lastError.clear();

    const QString data = privateDirectory();
    const QString directory = ensureDirectory(data, QStringLiteral("backups"));
    if (directory.isEmpty()) {
        m_lastError = tr("Could not create %1").arg(QDir(data).filePath(QStringLiteral("backups")));
    }
    return directory;
}

QString FileWriter::stateFile()
{
    const QString data = privateDirectory();
    return data.isEmpty() ? QString() : QDir(data).filePath(QStringLiteral("state.json"));
}

/*
 * Whether `path` is a file directly inside one of the folders the app writes to. The
 * folder is compared by its canonical path, so "..", a link to elsewhere or a path QML
 * built wrongly cannot reach any other place, and an existing link is never followed.
 */
bool FileWriter::mayWrite(const QString &path)
{
    const QFileInfo info(path);
    const QString parent = QFileInfo(info.absolutePath()).canonicalFilePath();
    if (parent.isEmpty() || info.fileName().isEmpty() || info.isSymLink() || info.isDir()) {
        return false;
    }

    QStringList allowed;
    const QString documents = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    if (!documents.isEmpty()) {
        allowed << QDir(documents).filePath(QStringLiteral("Health"));
    }
    const QString data = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (!data.isEmpty()) {
        allowed << data << QDir(data).filePath(QStringLiteral("backups"));
    }
    for (int i = 0; i < allowed.count(); ++i) {
        const QString canonical = QFileInfo(allowed.at(i)).canonicalFilePath();
        if (!canonical.isEmpty() && canonical == parent) {
            return true;
        }
    }
    return false;
}

bool FileWriter::writeFile(const QString &path, const QString &content)
{
    m_lastError.clear();

    if (!mayWrite(path)) {
        m_lastError = tr("This location is not allowed.");
        return false;
    }

    // Written to a temporary file and renamed into place on commit(), so a full disk
    // or a crash mid-write can no longer leave a truncated backup behind.
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        m_lastError = file.errorString();
        return false;
    }

    QTextStream out(&file);
    out.setCodec("UTF-8");
    out << content;
    out.flush();

    if (out.status() != QTextStream::Ok || file.error() != QFile::NoError) {
        m_lastError = file.errorString();
        file.cancelWriting();   // the temporary file is discarded, the old one kept
        return false;
    }

    if (!file.commit()) {
        m_lastError = file.errorString();
        return false;
    }
    return true;
}

QString FileWriter::readFile(const QString &path)
{
    m_lastError.clear();

    QFile file(path);
    if (file.size() > MaximumReadSize) {
        m_lastError = tr("This file is too large to be a backup.");
        return QString();
    }
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_lastError = file.errorString();
        return QString();
    }

    QTextStream in(&file);
    in.setCodec("UTF-8");
    const QString content = in.readAll();
    file.close();
    return content;
}

bool FileWriter::removeFile(const QString &path)
{
    m_lastError.clear();

    if (!mayWrite(path)) {
        m_lastError = tr("This location is not allowed.");
        return false;
    }
    QFile file(path);
    if (!file.exists()) {
        return true;
    }
    if (!file.remove()) {
        m_lastError = file.errorString();
        return false;
    }
    return true;
}

QStringList FileWriter::listFiles(const QString &dirPath, const QString &suffix)
{
    m_lastError.clear();

    QDir dir(dirPath);
    if (!dir.exists()) {
        m_lastError = tr("%1 does not exist.").arg(dirPath);
        return QStringList();
    }

    QStringList filters;
    filters << (QStringLiteral("*") + suffix);

    QStringList paths;
    const QFileInfoList entries = dir.entryInfoList(filters, QDir::Files | QDir::Readable, QDir::Time);
    for (int i = 0; i < entries.count(); ++i) {
        paths.append(entries.at(i).absoluteFilePath());
    }
    return paths;
}

QVariantMap FileWriter::fileInfo(const QString &path)
{
    const QFileInfo info(path);
    QVariantMap map;
    map.insert(QStringLiteral("exists"), info.exists() && info.isFile());
    map.insert(QStringLiteral("size"), info.exists() ? double(info.size()) : 0.0);
    map.insert(QStringLiteral("modified"),
               info.exists() ? double(info.lastModified().toMSecsSinceEpoch()) : 0.0);
    return map;
}

/*
 * QtQuick.LocalStorage keeps each database as <md5 of its name>.sqlite under the
 * engine's offline storage path. The app has exactly one; should a stray one ever sit
 * beside it, the one written last is the one in use.
 */
QString FileWriter::databaseFile() const
{
    const QQmlEngine *engine = qmlEngine(this);
    if (!engine) {
        return QString();
    }
    const QDir dir(engine->offlineStoragePath() + QStringLiteral("/Databases"));
    const QFileInfoList entries = dir.entryInfoList(QStringList() << QStringLiteral("*.sqlite"),
                                                    QDir::Files, QDir::Time);
    return entries.isEmpty() ? QString() : entries.first().absoluteFilePath();
}

double FileWriter::databaseModified()
{
    const QString database = databaseFile();
    if (database.isEmpty()) {
        return 0.0;
    }
    return double(QFileInfo(database).lastModified().toMSecsSinceEpoch());
}

QString FileWriter::saveRescueCopy()
{
    const QString database = databaseFile();
    const QString directory = exportDirectory();    // clears or sets m_lastError
    if (directory.isEmpty()) {
        return QString();
    }
    if (database.isEmpty()) {
        m_lastError = tr("There is no database file to copy.");
        return QString();
    }

    const QString stamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd-HHmmss"));
    const QString target = QDir(directory).filePath(QStringLiteral("health-rescue-%1.sqlite").arg(stamp));
    QFile source(database);
    if (!source.copy(target)) {
        m_lastError = source.errorString();
        return QString();
    }
    // A write that was interrupted leaves its journal beside the database; without it
    // the copy alone could not be repaired.
    const QString journal = database + QStringLiteral("-journal");
    if (QFile::exists(journal)) {
        QFile::copy(journal, target + QStringLiteral("-journal"));
    }
    return target;
}

QString FileWriter::lastError() const
{
    return m_lastError;
}
