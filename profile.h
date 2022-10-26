#ifndef PROFILE_H
#define PROFILE_H

#include <QObject>

class Profile : public QObject
{
    Q_OBJECT
public:
    explicit Profile(QObject *parent = nullptr);

signals:

};

#endif // PROFILE_H
