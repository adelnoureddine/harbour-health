/*
 * Health for SailfishOS
 * Copyright (C) 2022-2026 Adel Noureddine
 * Licensed under the GNU GPL 3 license only (GPL-3.0-only).
 */

#include "filewriter.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFileInfoList>
#include <QStandardPaths>
#include <QTextStream>

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

    QDir dir(documents);
    if (!dir.exists(QStringLiteral("Health")) && !dir.mkpath(QStringLiteral("Health"))) {
        m_lastError = tr("Could not create %1").arg(dir.filePath(QStringLiteral("Health")));
        return QString();
    }

    return dir.filePath(QStringLiteral("Health"));
}

bool FileWriter::writeFile(const QString &path, const QString &content)
{
    m_lastError.clear();

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        m_lastError = file.errorString();
        return false;
    }

    QTextStream out(&file);
    out.setCodec("UTF-8");
    out << content;
    out.flush();

    if (out.status() != QTextStream::Ok || file.error() != QFile::NoError) {
        m_lastError = file.errorString();
        file.close();
        return false;
    }

    file.close();
    return true;
}

QString FileWriter::readFile(const QString &path)
{
    m_lastError.clear();

    QFile file(path);
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

QString FileWriter::lastError() const
{
    return m_lastError;
}
