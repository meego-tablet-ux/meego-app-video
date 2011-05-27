/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef MYITEM_H
#define MYITEM_H

#include <QtDeclarative/QDeclarativeItem>
#include <QtCore/QVariant>
#include <QtCore/QSettings>

class QmlSetting : public QDeclarativeItem
{
    Q_OBJECT
    Q_DISABLE_COPY(QmlSetting)

    Q_PROPERTY(QString organization READ organization WRITE setOrganization NOTIFY organizationChanged)
    Q_PROPERTY(QString application READ application WRITE setApplication NOTIFY applicationChanged)

public:

    QmlSetting(QDeclarativeItem *parent = 0);
    ~QmlSetting();

    QString organization();
    void setOrganization(const QString& value);

    QString application();
    void setApplication(const QString& value);

    void componentComplete();

signals:
    void organizationChanged();
    void applicationChanged();
    void valueChanged(const QString& key, QVariant value);

public slots:
    QVariant get(const QString& key);
    void set(const QString& key, QVariant value);


private slots:
    void refresh();

private:
    QString m_organization;
    QString m_application;
    QSettings *m_settings;

};

QML_DECLARE_TYPE(QmlSetting)

#endif // MYITEM_H

