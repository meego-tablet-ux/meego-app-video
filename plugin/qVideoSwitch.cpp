#include "qVideoSwitcher.h"
#include "MeeGoVideoSwitch.h"

qVideoSwitcher::qVideoSwitcher(QObject *parent)
    :QObject(parent), m_videoSwitch(new MeeGoVideoSwitch())
{}

qVideoSwitcher::~qVideoSwitcher() { delete m_videoSwitch; }

void qVideoSwitcher::toClone() { m_videoSwitch->toClone(); }

void qVideoSwitcher::toExtend() { m_videoSwitch->toExtend(); }

void qVideoSwitcher::toSingle() { m_videoSwitch->toSingle(); }

void qVideoSwitcher::toVideoExtend() { m_videoSwitch->toVideoExtend(); }

bool qVideoSwitcher::isHDMIconnected() const
{
    return m_videoSwitch->isHDMIconnected();
}
