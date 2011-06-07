/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Media 0.1
import QtMultimediaKit 1.1
import MeeGo.App.Video.VideoPlugin 1.0
import MeeGo.Sharing 0.1
import MeeGo.Sharing.UI 0.1
import "functions.js" as Code

Window {
    id: window

    property string labelAppName: qsTr("Videos")
    property string topicAll: qsTr("All")
    property string topicAdded: qsTr("Recently added")
    property string topicViewed: qsTr("Recently viewed")
    property string topicUnwatched: qsTr("Unwatched")
    property string topicFavorites: qsTr("Favorites")

    property string labelConfirmDelete: qsTr("Delete")
    property string labelCancel: qsTr("Cancel")
    property string labelPlay: qsTr("Play")
    property string labelFavorite: qsTr("Favorite")
    property string labelUnFavorite: qsTr("Unfavorite")
    property string labelcShare: qsTr("Share")
    property string labelDelete: qsTr("Delete")
    property string labelMultiSelect:qsTr("Select multiple videos")
    property bool multiSelectMode: false
    property variant targetState: StateData {}
    property variant currentState: StateData {
        onPositionChanged: {
            console.log("POSITION: " + currentState.position);
        }
        onUriChanged: {
            console.log("URI: " + currentState.uri);
        }
        onPageChanged: {
            console.log("PAGE: " + currentState.page);
        }
        onFilterChanged: {
            console.log("FILTER: " + currentState.filter);
        }
        onCommandChanged: {
            console.log("COMMAND: " + currentState.command);
        }
    }

    property int videoToolbarHeight: 55
    property int videoThumblistHeight: 75
    property bool isLandscape: (window.inLandscape || window.inInvertedLandscape)

    signal setState()
    signal quietCmdReceived(string cmd)

    property variant resourceManager: ResourceManager {
        name: "player"
        type: ResourceManager.VideoApp
        onStartPlaying: {
            window.quietCmdReceived("play");
        }
        onStopPlaying: {
            window.quietCmdReceived("pause");
        }
    }

    SaveRestoreState {
        id: stateManager
        onSaveRequired: {
            setValue("page", currentState.page);
            setValue("uri", currentState.uri);
            setValue("command", currentState.command);
            setValue("position", currentState.position);
            setValue("filter", currentState.filter);
            sync();
        }
    }

    Timer {
        id: startupTimer
        interval: 2000
        repeat: false
    }
    
    Component.onCompleted: {
        switchBook( landingScreenContent )
        startupTimer.start();
    }

    // an editor model, used to do things like tag arbitrary items as favorite/viewed
    property variant editorModel: VideoListModel {
        type:VideoListModel.Editor
        limit: 0
        sort: VideoListModel.SortByDefault
    }

    property variant masterVideoModel: VideoListModel {
        type:VideoListModel.ListofAll
        limit: 0
        sort: VideoListModel.SortByTitle
        onFilterChanged: {
            currentState.filter = masterVideoModel.filter;
        }
        onTotalChanged: {
            topicAll = qsTr("All (%1 videos)").arg(masterVideoModel.total);
        }
        onItemAvailable: {
            var itemid = Code.getID(identifier);
            targetState.uri = masterVideoModel.datafromID(itemid, MediaItem.URI);
            window.setState();
        }
        onDatabaseInitComplete: {
            if(stateManager.restoreRequired)
            {
                targetState.set(stateManager.value("page"),
                                stateManager.value("command"),
                                stateManager.value("uri"),
                                stateManager.value("position"),
                                stateManager.value("filter"));
                window.setState();
            }
        }
    }

    overlayItem: Item {
        id: globalItems
        z: 1000
        anchors.fill: parent

        ShareObj {
            id: shareObj
            shareType: MeeGoUXSharingClientQmlObj.ShareTypeVideo
            onSharingComplete: {
                if(multiSelectMode)
                {
                    masterVideoModel.clearSelected();
                    shareObj.clearItems();
                    multiSelectMode = false;
                }
            }
        }

        TopItem { id: topItem }
    }

    QmlSetting{
        id: settings
        organization: "MeeGo"
        application:"meego-app-video"
    }

    Connections {
        target: mainWindow
        onCall: {
            if(parameters[0] == "playVideo")
            {
                targetState.set(1, "play", "", 0, VideoListModel.FilterAll);
                masterVideoModel.requestItem(parameters[1]);
            }
            else if(parameters[0] == "setState")
            {
                Code.forceState(parameters[1]);
            }
            else
            {
                targetState.set(1, parameters[0], "", -1, -1);
                window.setState();
            }
        }
    }

    Component {
        id: landingScreenContent
        LandingPage {
        }
    }  

    Component {
        id: detailViewContent
        DetailPage {
        }
    }
}

