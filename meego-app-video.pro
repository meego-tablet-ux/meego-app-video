VERSION = 0.2.21
TEMPLATE = subdirs
SUBDIRS += plugin

OTHER_FILES += *.qml *.js

qmlfiles.files += *.qml *.js
qmlfiles.path += $$INSTALL_ROOT/usr/share/$$TARGET

desktop.files += *.desktop
desktop.path += $$INSTALL_ROOT/usr/share/applications

INSTALLS += qmlfiles desktop

TRANSLATIONS += main.qml DetailPage.qml LandingPage.qml NoContentAdded.qml NoContentFavorite.qml NoContentUnwatched.qml NoContentViewed.qml NoVideosNotification.qml
PROJECT_NAME = meego-app-video

dist.commands += rm -fR $${PROJECT_NAME}-$${VERSION} &&
dist.commands += git clone . $${PROJECT_NAME}-$${VERSION} &&
dist.commands += rm -fR $${PROJECT_NAME}-$${VERSION}/.git &&
dist.commands += mkdir -p $${PROJECT_NAME}-$${VERSION}/ts &&
dist.commands += lupdate $${TRANSLATIONS} -ts $${PROJECT_NAME}-$${VERSION}/ts/$${PROJECT_NAME}.ts &&
dist.commands += tar jcpvf $${PROJECT_NAME}-$${VERSION}.tar.bz2 $${PROJECT_NAME}-$${VERSION}
QMAKE_EXTRA_TARGETS += dist
