/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Labs.Components 0.1 as Labs

NoContent {
    id: noContent
    Labs.ApplicationsModel {
        id: appsModel
        directories: [ "/usr/share/meego-ux-appgrid/applications", "/usr/share/applications", "~/.local/share/applications" ]
    }
    notification: Item {
        width: parent.width
        height: Math.max(col.height, button.height)
        Column {
            id: col
            anchors.left: parent.left
            anchors.right: button.left
            Text {
                width: parent.width
                text: qsTr("You have no videos on this tablet")
                font.pixelSize: theme_fontPixelSizeLarge*2
                wrapMode: Text.WordWrap
                height: paintedHeight + 20
            }
            Text {
                width: parent.width
                text: qsTr("Download or copy your videos onto the tablet. Connect the tablet to your computer with a USB cable, via WiFi or bluetooth.")
                font.pixelSize: theme_fontPixelSizeLarge
                wrapMode: Text.WordWrap
                height: paintedHeight + 20
            }
            Text {
                width: parent.width
                text: qsTr("You can also record your own videos using the tablet.")
                font.pixelSize: theme_fontPixelSizeLarge
                wrapMode: Text.WordWrap
            }
        }
        Button {
            id: button
            text: qsTr("Record a video")
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                appsModel.launch( "/usr/bin/meego-qml-launcher --opengl --app meego-app-camera --fullscreen")
            }
        }
    }
}
