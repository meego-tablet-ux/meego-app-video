/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "qmlsettings.h"

#include <QtDeclarative/qdeclarative.h>

QmlSetting::QmlSetting(QDeclarativeItem *parent):
        QDeclarativeItem(parent)
{
    // By default, QDeclarativeItem does not draw anything. If you subclass
    // QDeclarativeItem to create a visual item, you will need to uncomment the
    // following line:

    // setFlag(ItemHasNoContents, false);
}

QmlSetting::~QmlSetting()
{
    delete m_settings;
}

QString QmlSetting::organization()
{
    return m_organization;
}

void QmlSetting::setOrganization(const QString& value)
{
    m_organization = value;
    emit organizationChanged();
}

QString QmlSetting::application()
{
    return m_application;
}

void QmlSetting::setApplication(const QString& value)
{
    m_application = value;
    emit applicationChanged();
}

void QmlSetting::componentComplete()
{
    m_settings = new QSettings(m_organization,m_application);
    connect(this,SIGNAL(applicationChanged()),this,SLOT(refresh()));
    connect(this,SIGNAL(organizationChanged()),this,SLOT(refresh()));
}

QVariant QmlSetting::get(const QString& key)
{
    return m_settings->value(key, 0);
}

void QmlSetting::set(const QString& key, QVariant value)
{
    m_settings->setValue(key, value);
    emit valueChanged(key, value);
}

void QmlSetting::refresh()
{
    delete m_settings;
    m_settings = new QSettings(m_organization,m_application);
}
