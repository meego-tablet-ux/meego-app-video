TEMPLATE = lib
TARGET = VideoPlugin 
QT += declarative
CONFIG += qt plugin
OBJECTS_DIR = .obj
MOC_DIR = .moc
PKGCONFIG += xrandr
LIBS += -lXrandr
TARGET = $$qtLibraryTarget($$TARGET)
DESTDIR = $$TARGET
# Input
SOURCES += \
    plugin.cpp \
    MeeGoVideoSwitch.cpp \
    qVideoSwitch.cpp

HEADERS += \
    plugin.h \
    MeeGoVideoSwitch.h \
    qVideoSwitcher.h

OTHER_FILES = qmldir

QMAKE_POST_LINK = cp qmldir $$DESTDIR

qmlfiles.files += $$TARGET
qmlfiles.path += $$[QT_INSTALL_IMPORTS]/MeeGo/App/Video/
INSTALLS += qmlfiles
