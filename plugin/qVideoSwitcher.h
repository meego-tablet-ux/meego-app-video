#ifndef QVIDEOSWITCHER_H
#define QVIDEOSWITCHER_H

#include <QObject>

class MeeGoVideoSwitch;

class qVideoSwitcher : public QObject {
    Q_OBJECT

public:
    explicit qVideoSwitcher(QObject * parent = 0);
    ~qVideoSwitcher();

    Q_INVOKABLE bool isHDMIconnected() const;
    Q_INVOKABLE void toClone();
    Q_INVOKABLE void toSingle();
    Q_INVOKABLE void toExtend();
    Q_INVOKABLE void toVideoExtend();

private:
    MeeGoVideoSwitch * m_videoSwitch;
};

#endif // QVIDEOSWITCHER_H
