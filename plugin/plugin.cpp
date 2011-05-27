#include <QtDeclarative/qdeclarative.h>

#include "plugin.h"
#include "qVideoSwitcher.h"
#include "qmldbusvideo.h"
#include "qmlsettings.h"

void qVideoSwitchPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<qVideoSwitcher>(uri, 0, 1, "VideoSwitcher");
    qmlRegisterType<QmlDBusVideo>(uri, 0, 1, "QmlDBusVideo");
    qmlRegisterType<QmlSetting>(uri, 0, 1, "QmlSetting");
}

Q_EXPORT_PLUGIN2(VideoPlugin, qVideoSwitchPlugin)

