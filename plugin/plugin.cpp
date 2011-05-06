#include <QtDeclarative/qdeclarative.h>

#include "plugin.h"
#include "qVideoSwitcher.h"
#include "qmldbusvideo.h"

void qVideoSwitchPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<qVideoSwitcher>(uri, 0, 1, "VideoSwitcher");
    qmlRegisterType<QmlDBusVideo>(uri, 0, 1, "QmlDBusVideo");
}

Q_EXPORT_PLUGIN2(VideoPlugin, qVideoSwitchPlugin)

