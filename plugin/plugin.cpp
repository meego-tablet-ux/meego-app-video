#include <QtDeclarative/qdeclarative.h>

#include "plugin.h"
#include "qVideoSwitcher.h"

void qVideoSwitchPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<qVideoSwitcher>(uri, 0, 1, "VideoSwitcher");
}

Q_EXPORT_PLUGIN2(VideoPlugin, qVideoSwitchPlugin)

