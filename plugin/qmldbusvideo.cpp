/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "qmldbusvideo.h"

#include <QDebug>
#include <QDBusConnection>

QmlDBusVideo::QmlDBusVideo(QObject *parent) :
  QObject(parent)
{
  m_nowNextTracks << "" << "" << "";
  m_state = "stopped";
  new VideoDBusAdaptor(this);
  QDBusConnection::sessionBus().registerObject("/com/meego/app/video", this);
  QDBusConnection::sessionBus().registerService("com.meego.app.video");
}

QmlDBusVideo::~QmlDBusVideo()
{
}

QString QmlDBusVideo::state() const
{
  return m_state;
}

void QmlDBusVideo::setState(QString state)
{
  m_state = state;
  emit stateChanged();
}

QStringList QmlDBusVideo::nowNextTracks() const
{
  return m_nowNextTracks;
}

void QmlDBusVideo::setNowNextTracks(QStringList nowNextTracks)
{
  m_nowNextTracks = nowNextTracks;
  emit nowNextTracksChanged();
}

VideoDBusAdaptor::VideoDBusAdaptor(QmlDBusVideo *obj) : QDBusAbstractAdaptor(obj), m_QmlDBusVideo(obj)
{
  setAutoRelaySignals(true) ;
}

VideoDBusAdaptor::~VideoDBusAdaptor()
{

}

QString VideoDBusAdaptor::state() const
{
  return m_QmlDBusVideo->state();
}

void VideoDBusAdaptor::setState(QString state)
{
  m_QmlDBusVideo->setState(state);
}

QStringList VideoDBusAdaptor::nowNextTracks() const
{
  return m_QmlDBusVideo->nowNextTracks();
}

void VideoDBusAdaptor::setNowNextTracks(QStringList nowNextTracks)
{
  m_QmlDBusVideo->setNowNextTracks(nowNextTracks);
}

void VideoDBusAdaptor::next()
{
  emit m_QmlDBusVideo->next();
}

void VideoDBusAdaptor::prev()
{
  emit m_QmlDBusVideo->prev();
}

void VideoDBusAdaptor::play()
{
  emit m_QmlDBusVideo->play();
}

void VideoDBusAdaptor::pause()
{
  emit m_QmlDBusVideo->pause();
}
