#ifndef QVIDEOSWITCH_PLUGIN_H
#define QVIDEOSWITCH_PLUGIN_H

#include <QtDeclarative/QDeclarativeExtensionPlugin>

class qVideoSwitchPlugin : public QDeclarativeExtensionPlugin
{
    Q_OBJECT

public:
    void registerTypes(const char *uri);
};

#endif // QVIDEOSWITCH_PLUGIN_H

