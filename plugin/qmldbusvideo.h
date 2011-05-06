/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#ifndef QMLDBUSVIDEO_H
#define QMLDBUSVIDEO_H

#include <QObject>
#include <QDBusAbstractAdaptor>
#include <QString>
#include <QStringList>

class QmlDBusVideo : public QObject
{
  Q_OBJECT
  Q_PROPERTY(QString state READ state WRITE setState NOTIFY stateChanged)
  Q_PROPERTY(QStringList nowNextTracks READ nowNextTracks WRITE setNowNextTracks NOTIFY nowNextTracksChanged)

  friend class VideoDBusAdaptor;

public:
  explicit QmlDBusVideo(QObject *parent = 0);
  ~QmlDBusVideo();

  QString state() const;
  void setState(QString state);
  QStringList nowNextTracks() const;
  void setNowNextTracks(QStringList nowNextTracks);

signals:
  void stateChanged();
  void nowNextTracksChanged();
  void next();
  void prev();
  void play();
  void pause();

private:
  QString m_state;
  QStringList m_nowNextTracks;
};

class VideoDBusAdaptor : public QDBusAbstractAdaptor
{
  Q_OBJECT
  Q_CLASSINFO("D-Bus Interface", "com.meego.app.video")
  Q_PROPERTY(QString state READ state WRITE setState NOTIFY stateChanged)
  Q_PROPERTY(QStringList nowNextTracks READ nowNextTracks WRITE setNowNextTracks NOTIFY nowNextTracksChanged)


public:
  explicit VideoDBusAdaptor(QmlDBusVideo *obj);
  ~VideoDBusAdaptor();
  QString state() const;
  void setState(QString state);
  QStringList nowNextTracks() const;
  void setNowNextTracks(QStringList nowNextTracks);

public slots:
  void next();
  void prev();
  void play();
  void pause();

signals:
  void stateChanged();
  void nowNextTracksChanged();

private:
  QmlDBusVideo *m_QmlDBusVideo;
};

#endif // QMLDBUSVIDEO_H
