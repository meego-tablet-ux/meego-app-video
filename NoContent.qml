/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1

NoContentBase {
    id: noContent
    property string title: ""
    property string description: ""
    property string button1Text: ""
    property string button2Text: ""
    signal button1Clicked();
    signal button2Clicked();
    notification: Item {
        id: notif
        width: parent.width
        height: isLandscape ? Math.max(col.height, buttons.height) : col.height + buttons.height
        Grid {
            width: parent.width
            columns: isLandscape ? 2 : 1
            Column {
                id: col
                width: isLandscape ? parent.width - buttons.width : parent.width
                Text {
                    width: parent.width
                    text: title
                    font.pixelSize: theme_fontPixelSizeLarge
                    wrapMode: Text.WordWrap
                    height: paintedHeight + 20
                }
                Text {
                    id: desc
                    visible: description != ""
                    width: parent.width
                    text: description
                    font.pixelSize: theme_fontPixelSizeNormal
                    wrapMode: Text.WordWrap
                    height: paintedHeight
                }
            }
            Item {
                width: isLandscape ? buttons.width : notif.width
                height: isLandscape ? notif.height : buttons.height
                Grid {
                    id: buttons
                    columns: isLandscape ? 1 : 3
                    visible: button1Text != "" || button2Text != ""
                    anchors.verticalCenter: isLandscape ? parent.verticalCenter : undefined
                    anchors.horizontalCenter: isLandscape ? undefined : parent.horizontalCenter
                    width: isLandscape ? Math.max(button1.width, button2.width) : button1.width + padding.width + button2.width

                    Button {
                        id: button1
                        text: button1Text
                        onClicked: {
                            noContent.button1Clicked()
                        }
                    }
                    Item {
                        id: padding
                        visible: button2.visible
                        width: 100
                        height: button2.height
                    }
                    Button {
                        id: button2
                        visible: button2Text != ""
                        text: button2Text
                        onClicked: {
                            noContent.button2Clicked()
                        }
                    }
                }
            }
        }
    }
}
