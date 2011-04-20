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
import QtMultimediaKit 1.1
import MeeGo.Media 0.1
import MeeGo.Sharing 0.1

import "functions.js" as Code

Window {
    id: window

    property string topicAll: qsTr("All")
    property string topicAdded: qsTr("Recently added")
    property string topicViewed: qsTr("Recently viewed")
    property string topicUnwatched: qsTr("Unwatched")
    property string topicFavorites: qsTr("Favorites")

    property string labelVideoTitle: ""
    property string labelConfirmDelete: qsTr("Yes, Delete")
    property string labelCancel: qsTr("Cancel")
    property string videoSearch: ""
    property string videoSource: ""
    property string favoriteColor: "#ff8888"
    property string currentVideoID: ""
    property bool currentVideoFavorite: false
    property string labelPlay: qsTr("Play")
    property string labelFavorite: qsTr("Favorite")
    property string labelUnFavorite: qsTr("Unfavorite")
    property string labelcShare: qsTr("Share")
    property string labelDelete: qsTr("Delete")
    property string labelMultiSelect:qsTr("Select Multiple Videos")
    property bool multiSelectMode: false

    property int animationDuration: 500
    property int videoIndex: 0

    property int videoToolbarHeight: 55
    property int videoThumblistHeight: 75
    property int videoListState: 0
    property bool showVideoToolbar: false
    property bool videoCropped: false
    property bool videoVisible: false

    signal cmdReceived(string cmd, string cdata)

    Timer {
        id: startupTimer
        interval: 2000
        repeat: false
    }

    Component.onCompleted: {
        switchBook( landingScreenContent )
        startupTimer.start();
    }

    function enterFullscreen()
    {
        showVideoToolbar = false;
        fullContent = true;
    }

    function exitFullscreen()
    {
        fullContent = false;
        showVideoToolbar = true;
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
        onTotalChanged: {
            topicAll = qsTr("All (%1 videos)").arg(masterVideoModel.total);
        }
        onItemAvailable: {
            window.cmdReceived("playVideo", identifier);
        }
    }

    Labs.ShareObj {
        id: shareObj
        shareType: MeeGoUXSharingClientQmlObj.ShareTypeVideo
    }

    Connections {
        target: mainWindow
        onCall: {
            if(parameters[0] == "playVideo")
                masterVideoModel.requestItem(parameters[1]);
            else if(parameters[0] == "play")
                window.cmdReceived(parameters[0], "");
            else if(parameters[0] == "pause")
                window.cmdReceived(parameters[0], "");
        }
    }

    Component {
        id: landingScreenContent
        AppPage {
            id: landingPage
            anchors.fill: parent
            pageTitle: qsTr("Videos")
            property bool infocus: true
            onActivated : {
                infocus = true;
                if(currentVideoID != "")
                    editorModel.setPlayStatus(currentVideoID, VideoListModel.Stopped);
                window.disableToolBarSearch = false;
                videoVisible = false;
                fullContent = false;
                showVideoToolbar = false;
            }
            onDeactivated : { infocus = false; }

            ModalDialog {
                id: deleteItemDialog
                title: labelDelete
                acceptButtonText: labelConfirmDelete
                cancelButtonText: labelCancel
                property variant payload
                onPayloadChanged:{
                    contentItem.title = payload.mtitle;
                }
                onAccepted: {
                    masterVideoModel.destroyItemByID(payload.mitemid);
                }
                content: Item {
                    id: contentItem
                    anchors.fill: parent
                    property alias title : titleText.text
                    clip: true
                    Text{
                        id: titleText
                        text : qsTr("Video name")
                        anchors.top: parent.top
                        width:  parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: qsTr("If you delete this, it will be removed from your device")
                        anchors.top:titleText.bottom
                        width:  parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: theme_fontPixelSizeMedium
                    }
                }
            }

            ModalDialog {
                id: deleteMultipleItemsDialog
                property int deletecount: 0
                title: (deletecount < 2)?qsTr("Permanently delete this video?"):qsTr("Permanently delete these %1 videos?").arg(deletecount)
                acceptButtonText: labelConfirmDelete
                cancelButtonText:labelCancel
                onAccepted: {
                    masterVideoModel.destroyItemsByID(masterVideoModel.getSelectedIDs());
                    masterVideoModel.clearSelected();
                    shareObj.clearItems();
                    multiSelectMode = false;
                }
                content: Item {
                    anchors.fill: parent
                    clip: true
                    Text {
                        text: qsTr("If you delete these, they will be removed from your device")
                        anchors.verticalCenter:parent.verticalCenter
                        width:  parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: theme_fontPixelSizeMedium
                    }
                }
            }

            function playvideo(payload)
            {
                videoIndex = payload.mindex;
                currentVideoID = payload.mitemid;
                currentVideoFavorite = payload.mfavorite;
                videoSource = payload.muri;
                fullContent = true;
                labelVideoTitle = payload.mtitle;
                editorModel.setViewed(payload.mitemid);
                editorModel.setPlayStatus(payload.mitemid, VideoListModel.Playing);
                window.switchBook(detailViewContent);
            }

            Connections {
                target: window
                onSearch: {
                    videoSearch = needle;
                    landingScreenGridView.opacity = 0;
                    masterVideoModel.search = videoSearch;
                    if(masterVideoModel.filter != VideoListModel.FilterSearch)
                        masterVideoModel.filter = VideoListModel.FilterSearch
                    videoListState = (videoListState + 1)%2;
                }
            }

            Connections {
                target: window
                onCmdReceived: {
                    if(infocus)
                    {
                        console.log("Landing Remote Call: " + cmd + " " + cdata);

                        if (cmd == "playVideo")
                        {
                            var itemid;
                            if(masterVideoModel.isURN(cdata))
                                itemid = masterVideoModel.getIDfromURN(cdata);
                            else
                                itemid = cdata;

                            if(itemid != "")
                            {
                                /* need to filter on all */
                                masterVideoModel.filter = VideoListModel.FilterAll

                                videoIndex = masterVideoModel.itemIndex(itemid);
                                var title;
                                var uri;
                                if(masterVideoModel.isURN(cdata))
                                {
                                    title = masterVideoModel.getTitlefromURN(cdata);
                                    uri = masterVideoModel.getURIfromURN(cdata);
                                }
                                else
                                {
                                    title = masterVideoModel.getTitlefromID(cdata);
                                    uri = masterVideoModel.getURIfromID(cdata);
                                }

                                currentVideoID = itemid;
                                currentVideoFavorite = masterVideoModel.isFavorite(itemid);
                                videoSource = uri;
                                fullContent = false;
                                labelVideoTitle = title;
                                window.addPage(detailViewContent);
                                editorModel.setViewed(itemid);
                                editorModel.setPlayStatus(itemid, VideoListModel.Playing);
                            }
                        }
                    }
                }
            }

            ModalContextMenu {
                id: contextMenu
                property alias payload: contextActionMenu.payload
                property alias model: contextActionMenu.model
                property variant shareModel: []
                content: ActionMenu {
                    id: contextActionMenu
                    property variant payload: undefined
                    onTriggered: {
                        shareObj.clearItems();
                        if (model[index] == labelPlay)
                        {
                            // Play
                            landingPage.playvideo(payload);
                            contextMenu.hide();
                        }
                        else if ((model[index] == labelFavorite)||(model[index] == labelUnFavorite))
                        {
                            // Favorite/unfavorite
                            Code.changeItemFavorite(payload);
                            contextMenu.hide();
                        }
                        else if (model[index] == labelDelete)
                        {
                            // Delete
                            deleteItemDialog.payload = payload;
                            deleteItemDialog.show();
                            contextMenu.hide();
                        }
                        else if (model[index] == labelMultiSelect)
                        {
                            // multi select mode on
                            multiSelectMode = true;
                            contextMenu.hide();
                        }
                        else if (model[index] == labelcShare)
                        {
                            // Share
                            shareObj.clearItems();
                            shareObj.addItem(payload.muri) // URI
                            contextMenu.shareModel = shareObj.serviceTypes;
                            contextMenu.shareModel = contextMenu.shareModel.concat(labelCancel);
                            contextMenu.subMenuModel = contextMenu.shareModel;
                            contextMenu.subMenuPayload = contextMenu.shareModel;
                            contextMenu.subMenuVisible = true;
                        }
                    }
                }
                onSubMenuTriggered: {
                    if (shareModel[index] == labelCancel)
                    {
                        contextMenu.subMenuVisible = false;
                    }
                    else
                    {
                        var svcTypes = shareObj.serviceTypes;
                        for (x in svcTypes) {
                            if (shareModel[index] == svcTypes[x]) {
                                shareObj.showContext(shareModel[index], contextMenu.x, contextMenu.y);
                                break;
                            }
                        }
                        contextMenu.hide();
                    }
                }
            }
            Connections {
                target: masterVideoModel
                onTotalChanged: {
                    topicAll = qsTr("All (%1 videos)").arg(masterVideoModel.total);
                    window.actionMenuModel = [topicAll, topicAdded, topicViewed, topicUnwatched, topicFavorites];
                }
            }
            actionMenuModel: [topicAll, topicAdded, topicViewed, topicUnwatched, topicFavorites]
            actionMenuPayload: ["all", "added", "viewed", "unwatched", "favorites"]
            onActionMenuTriggered: {
                if (selectedItem == "all") {
                    landingScreenGridView.opacity = 0;
                    if(masterVideoModel.filter != VideoListModel.FilterAll)
                    {
                        masterVideoModel.filter = VideoListModel.FilterAll
                        masterVideoModel.sort = VideoListModel.SortByTitle;
                    }
                }else if(selectedItem == "added") {
                    landingScreenGridView.opacity = 0;
                    if(masterVideoModel.filter != VideoListModel.FilterAdded)
                    {
                        masterVideoModel.filter = VideoListModel.FilterAdded
                        masterVideoModel.sort = VideoListModel.SortByAddedTime;
                    }
                }else if(selectedItem == "viewed") {
                    landingScreenGridView.opacity = 0;
                    if(masterVideoModel.filter != VideoListModel.FilterViewed)
                    {
                        masterVideoModel.filter = VideoListModel.FilterViewed
                        masterVideoModel.sort = VideoListModel.SortByAccessTime;
                    }
                }else if(selectedItem == "unwatched") {
                    landingScreenGridView.opacity = 0;
                    if(masterVideoModel.filter != VideoListModel.FilterUnwatched)
                    {
                        masterVideoModel.filter = VideoListModel.FilterUnwatched
                        masterVideoModel.sort = VideoListModel.SortByTitle;
                    }
                }else if(selectedItem == "favorites") {
                    landingScreenGridView.opacity = 0;
                    if(masterVideoModel.filter != VideoListModel.FilterFavorite)
                    {
                        masterVideoModel.filter = VideoListModel.FilterFavorite
                        masterVideoModel.sort = VideoListModel.SortByTitle;
                    }
                }else if(selectedItem == "search") {
                    landingScreenGridView.opacity = 0;
                    masterVideoModel.search = videoSearch;
                    if(masterVideoModel.filter != VideoListModel.FilterSearch)
                    {
                        masterVideoModel.filter = VideoListModel.FilterSearch
                        masterVideoModel.sort = VideoListModel.SortByTitle;
                    }
                }
                videoListState = (videoListState + 1)%2;
            }

            Item {
                id: landingItem
                anchors.fill: parent

                Item {
                    id: noVideosScreen
                    anchors.centerIn: parent
                    height: parent.height/2
                    width: (window.inLandscape)?(parent.width/2):(parent.width/1.2)
                    visible: ((masterVideoModel.total == 0)&&(!startupTimer.running))
                    Text {
                        id: noVideosScreenText1
                        width: parent.width
                        text: qsTr("No videos added yet, do you want to start watching videos?")
                        font.pixelSize: window.height/17
                        anchors.top: parent.top
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        id: noVideosScreenText2
                        width: parent.width
                        text: qsTr("Start recording your own or upload your favourite shows.")
                        font.pixelSize: window.height/21
                        anchors.top: noVideosScreenText1.bottom
                        anchors.topMargin: window.height/24
                        wrapMode: Text.WordWrap
                    }
                }

                MediaGridView {
                    id: landingScreenGridView
                    type: videotype // video app = 0
                    selectionMode: multiSelectMode
                    showHeader: true
                    clip:true
                    opacity: 0
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.topMargin:3
                    cellWidth:(width- 15) / (window.inLandscape ? 7: 4)
                    cellHeight: cellWidth
                    model: masterVideoModel
                    defaultThumbnail: "image://theme/media/video_thumb_med"
                    footerHeight: multibar.height
                    onClicked:{
                        if(multiSelectMode)
                        {
                            masterVideoModel.setSelected(payload.mitemid, !masterVideoModel.isSelected(payload.mitemid));
                            if (masterVideoModel.isSelected(payload.mitemid))
                                shareObj.addItem(payload.muri);
                            else
                                shareObj.delItem(payload.muri);
                        }
                        else
                        {
                            videoIndex = payload.mindex;
                            currentVideoID = payload.mitemid;
                            currentVideoFavorite = payload.mfavorite;
                            videoSource = payload.muri;
                            fullContent = false;
                            labelVideoTitle = payload.mtitle;
                            window.addPage(detailViewContent);
                            editorModel.setViewed(payload.mitemid);
                            editorModel.setPlayStatus(payload.mitemid, VideoListModel.Playing);
                        }
                    }
                    onLongPressAndHold: {
                        if(!multiSelectMode)
                        {
                            var map = payload.mapToItem(topItem.topItem, mouseX, mouseY);
                            contextMenu.model = [labelPlay, ((payload.mfavorite)?labelUnFavorite:labelFavorite),
                                                 labelcShare, labelMultiSelect, labelDelete];
                            contextMenu.payload = payload;
                            topItem.calcTopParent()
                            contextMenu.setPosition( map.x, map.y );
                            contextMenu.show();
                        }
                    }
                    states: [
                        State {
                            name: "view0"
                            when: videoListState == 0
                            PropertyChanges {
                                target: landingScreenGridView
                                opacity: 1
                            }
                        },
                        State {
                            name: "view1"
                            when: videoListState == 1
                            PropertyChanges {
                                target: landingScreenGridView
                                opacity: 1
                            }
                        }
                    ]

                    transitions: [
                        Transition {
                            SequentialAnimation {
                                PropertyAnimation {
                                    properties: "opacity"
                                    duration: 500
                                    easing.type: Easing.OutSine
                                }
                            }
                        }
                    ]
                }

                MediaMultiBar {
                    id: multibar
                    height: (multiSelectMode)?55:0
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    landscape: window.inLandscape
                    showadd: false
                    onDeletePressed: {
                        if(masterVideoModel.selectionCount() > 0)
                        {
                            deleteMultipleItemsDialog.deletecount = masterVideoModel.selectionCount();
                            deleteMultipleItemsDialog.show();
                        }
                    }
                    onCancelPressed: {
                        masterVideoModel.clearSelected();
                        shareObj.clearItems();
                        multiSelectMode = false;
                    }
                    onSharePressed: {
                        if(shareObj.shareCount > 0)
                        {
                            var map = mapToItem(topItem.topItem, fingerX, fingerY);
                            contextShareMenu.model = shareObj.serviceTypes;
                            topItem.calcTopParent()
                            contextShareMenu.setPosition( map.x, map.y );
                            contextShareMenu.show();
                        }
                    }
                    states: [
                        State {
                            name: "showActionBar"
                            when: multiSelectMode
                            PropertyChanges {
                                target: multibar
                                opacity:1
                            }
                        },
                        State {
                            name: "hideActionBar"
                            when: !multiSelectMode
                            PropertyChanges {
                                target: multibar
                                opacity: 0
                            }
                        }
                    ]

                    transitions: [
                        Transition {
                            reversible: true
                            PropertyAnimation {
                                target: multibar
                                property: "opacity"
                                duration: 250
                            }
                        }
                    ]
                }

                ModalContextMenu {
                    id: contextShareMenu
                    property alias model: contextShareActionMenu.model
                    content: ActionMenu {
                        id: contextShareActionMenu
                        onTriggered: {
                            var svcTypes = shareObj.serviceTypes;
                            for (x in svcTypes) {
                                if (model[index] == svcTypes[x]) {
                                    shareObj.showContext(model[index], contextShareMenu.x, contextShareMenu.y);
                                    break;
                                }
                            }
                            contextMenu.hide();
                        }
                    }
                }
            }
            TopItem { id: topItem }
        }
    }  

    Component {
        id: detailViewContent
        AppPage {
            id: detailPage
            anchors.fill: parent
            pageTitle: labelVideoTitle
            property bool infocus: true
            onActivated : { infocus = true; }
            onDeactivated : { infocus = false; }

            ModalDialog {
                id: deleteItemDialog
                title: labelDelete
                acceptButtonText: labelConfirmDelete
                cancelButtonText: labelCancel
                onAccepted: {
                    masterVideoModel.destroyItemByID(currentVideoID);
                }
                content: Item {
                    id: contentItem
                    anchors.fill: parent
                    clip: true
                    Text{
                        id: titleText
                        text : labelVideoTitle
                        anchors.top: parent.top
                        width:  parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        text: qsTr("If you delete this, it will be removed from your device")
                        anchors.top:titleText.bottom
                        width:  parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: theme_fontPixelSizeMedium
                    }
                }
            }

            function playvideo(payload)
            {
                currentVideoID = payload.mitemid;
                currentVideoFavorite = payload.mfavorite;
                videoSource = payload.muri;
                labelVideoTitle = payload.mtitle;
                editorModel.setViewed(payload.mitemid);
                editorModel.setPlayStatus(payload.mitemid, VideoListModel.Playing);

                videoToolbar.ispause = true;
                video.source = videoSource;
                video.play();
                if(fullContent)
                    showVideoToolbar = false;
                else
                    showVideoToolbar = true;
                videoVisible = true;
            }

            Connections {
                target: window
                onCmdReceived: {
                    if(infocus)
                    {
                        console.log("Detail Remote Call: " + cmd + " " + cdata);

                        if (cmd == "playVideo")
                        {
                            var itemid;
                            if(masterVideoModel.isURN(cdata))
                                itemid = masterVideoModel.getIDfromURN(cdata);
                            else
                                itemid = cdata;

                            if(itemid != "")
                            {
                                /* need to filter on all */
                                masterVideoModel.filter = VideoListModel.FilterAll

                                if(itemid != videoThumbnailView.currentItem.mitemid)
                                {
                                    showVideoToolbar = false;
                                    fullContent = true;
                                    videoVisible = true;

                                    videoThumbnailView.show(false);

                                    videoThumbnailView.currentIndex = masterVideoModel.itemIndex(itemid);

                                    currentVideoID = videoThumbnailView.currentItem.mitemid;
                                    currentVideoFavorite = videoThumbnailView.currentItem.mfavorite;
                                    videoSource = videoThumbnailView.currentItem.muri;
                                    labelVideoTitle = videoThumbnailView.currentItem.mtitle;
                                    editorModel.setViewed(currentVideoID);
                                    editorModel.setPlayStatus(currentVideoID, VideoListModel.Playing);
                                    videoToolbar.ispause = true;

                                    video.source = videoSource;
                                }
                                video.play();
                            }
                        }
                        else if (cmd == "play")
                        {
                            videoToolbar.ispause = true;
                            if(!video.playing || video.paused)
                                video.play();
                        }
                        else if (cmd == "pause")
                        {
                            videoToolbar.ispause = false;
                            if(video.playing || !video.paused)
                                video.pause();
                        }
                    }
                }
            }

            ModalContextMenu {
                id: contextMenu
                property alias model: contextActionMenu.model
                property variant shareModel: []
                content: ActionMenu {
                    id: contextActionMenu
                    onTriggered: {
                        shareObj.clearItems();
                        if (model[index] == labelDelete)
                        {
                            // Delete
                            deleteItemDialog.show();
                            contextMenu.hide();
                        }
                        else
                        {
                            // Share
                            shareObj.clearItems();
                            shareObj.addItem(videoSource) // URI
                            var svcTypes = shareObj.serviceTypes;
                            for (x in svcTypes) {
                                if (model[index] == svcTypes[x]) {
                                    shareObj.showContext(model[index], contextMenu.x, contextMenu.y);
                                    break;
                                }
                            }
                            contextMenu.hide();
                        }
                    }
                }
            }

            Item {
                id: detailItem
                anchors.fill: parent

                property alias videoThumbList: videoThumbnailView

                Component.onCompleted: {
                    window.disableToolBarSearch = true;
//                    window.orientationLock = 1;
                    video.source = videoSource;
                    video.play();
                    if(fullContent)
                        showVideoToolbar = false;
                    else
                        showVideoToolbar = true;
                    videoVisible = true;
                }

//                Component.onDestruction: {
//                    window.orientationLock = Scene.noLock;
//                }

                MediaPreviewStrip {
                    id: videoThumbnailView
                    model: masterVideoModel
                    width: parent.width
                    showText: false
                    itemSpacing: 0
                    anchors.top: parent.top
                    anchors.topMargin: 5 + window.statusBar.height + detailPage.toolbarHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    currentIndex: videoIndex
                    z: 1000
                    onClicked: {
                        playvideo(element);
                    }
                }
                states: [
                    State {
                        name: "showtoolbar-mode"
                        when: !fullContent
                        PropertyChanges {
                            target: videoThumbnailView
                            anchors.topMargin: 5 + window.statusBar.height + detailPage.toolbarHeight
                        }
                    },
                    State {
                        name: "hidetoolbar-mode"
                        when: fullContent
                        PropertyChanges {
                            target: videoThumbnailView
                            anchors.topMargin: 5
                        }
                    }
                ]

                transitions: [
                    Transition {
                        from: "showtoolbar-mode"
                        to: "hidetoolbar-mode"
                        reversible: true
                        PropertyAnimation {
                            property: "anchors.topMargin"
                            duration: 250
                            easing.type: "OutSine"
                        }
                    }
                ]

                Rectangle {
                    id: videorect
                    width : 0
                    height : 0
                    color: "black"
                    Video {
                        id: video
                        anchors.centerIn: parent
                        height: ((parent.width * 3)/4) * (parent.height/window.height)
                        width: parent.width
                        autoLoad: true
                        onStopped: {
                            editorModel.setPlayStatus(currentVideoID, VideoListModel.Stopped);
                            videoThumbnailView.show(true);
                            if(fullContent)
                                exitFullscreen();
                        }
                        onPlayingChanged: {
                            if (!playing) {
                                window.inhibitScreenSaver = false;
                            }else {
                                window.inhibitScreenSaver = true;
                            }
                        }
                        onError: {
                        }

                        Component.onDestruction: {
                            console.log("Video object being destroyed");
                        }

                        Connections {
                            target: window
                            onWindowActiveChanged: {
                                if (!window.isActive && video.playing && !video.paused)
                                {
                                    if (fullContent)
                                        exitFullscreen();
                                    editorModel.setPlayStatus(currentVideoID, VideoListModel.Paused);
                                    videoToolbar.ispause = false;
                                    video.pause();
                                }
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill:parent
                        onClicked:{
                            if(fullContent)
                            {
                                fullContent = false;
                                showVideoToolbar = true;
                            }
                            else
                            {
                                showVideoToolbar = false;
                                fullContent = true;
                            }
                            videoVisible = true;
                            videoThumbnailView.hide();
                        }
                        onPressAndHold: {
                            var map = mapToItem(topItem.topItem, mouseX, mouseY);
                            var sharelist = shareObj.serviceTypes;
                            contextMenu.model = sharelist.concat(labelDelete);
                            topItem.calcTopParent()
                            contextMenu.setPosition( map.x, map.y );
                            contextMenu.show();
                        }
                    }

                    states: [
                        State {
                            name: "VideoLandscape"
                            when: videoVisible&&!videoCropped&&window.inLandscape
                            PropertyChanges {
                                target: videorect
                                width: detailPage.width;
                                height: detailPage.height;
                            }
                            PropertyChanges {
                                target: video
                                height: detailPage.height;
                            }
                        },
                        State {
                            name: "VideoPortrait"
                            when: videoVisible&&!videoCropped&&!window.inLandscape
                            PropertyChanges {
                                target: videorect
                                width: detailPage.width;
                                height: detailPage.height;
                            }
                            PropertyChanges {
                                target: video
                                height: detailPage.height;
                            }
                        },
                        State {
                            name: "VideoLandscapeCropped"
                            when: videoVisible&&videoCropped&&window.inLandscape
                            PropertyChanges {
                                target: videorect
                                width: detailPage.width;
                                height: detailPage.height;
                            }
                        },
                        State {
                            name: "VideoPortraitCropped"
                            when: videoVisible&&videoCropped&&!window.inLandscape
                            PropertyChanges {
                                target: videorect
                                width: detailPage.width;
                                height: detailPage.height;
                            }
                        },
                        State {
                            name: "VideoInvisible"
                            when: !videoVisible
                            PropertyChanges {
                                target: videorect
                                width: 0;
                                height: 0;
                            }
                        }
                    ]
                }

                MediaToolbar {
                    id: videoToolbar
                    anchors.bottom: parent.bottom
                    width: parent.width
                    showprev: true
                    showplay: true
                    shownext: true
                    showprogressbar: true
                    showvolume: true
                    showfavorite: true
                    isfavorite: currentVideoFavorite
                    onPrevPressed: {
                        videoThumbnailView.show(false);
                        if (videoThumbnailView.currentIndex == 0)
                            videoThumbnailView.currentIndex = videoThumbnailView.count - 1;
                        else
                            videoThumbnailView.currentIndex--;

                        playvideo(videoThumbnailView.currentItem);
                    }
                    onPlayPressed: {
                        if (video.paused)
                        {
                            video.play();
                            editorModel.setPlayStatus(currentVideoID, VideoListModel.Playing);
                        }
                        ispause = true;
                    }
                    onPausePressed: {
                        if (video.playing && !video.paused)
                        {
                            video.pause();
                            editorModel.setPlayStatus(currentVideoID, VideoListModel.Paused);
                        }
                        ispause = false;
                    }
                    onNextPressed: {
                        videoThumbnailView.show(true);
                        if (videoThumbnailView.currentIndex < (videoThumbnailView.count -1))
                            videoThumbnailView.currentIndex++;
                        else
                            videoThumbnailView.currentIndex = 0;

                        playvideo(videoThumbnailView.currentItem);
                    }
                    Connections {
                        target: video
                        onPositionChanged: {
                            var msecs = video.duration - video.position;
                            videoToolbar.remainingTimeText = Code.formatTime(msecs/1000);
                            videoToolbar.elapsedTimeText = Code.formatTime(video.position/1000);
                        }
                    }
                    onSliderMoved: {
                        if (video.seekable) {
                            progressBarConnection.target = null
                            video.position = video.duration * videoToolbar.sliderPosition;
                            progressBarConnection.target = video
                        }
                    }
                    Connections {
                        id: progressBarConnection
                        target: video
                        onPositionChanged: {
                            if (video.duration != 0) {
                                videoToolbar.sliderPosition = video.position/video.duration;
                            }
                        }
                    }
                    onFavoritePressed: {
                        currentVideoFavorite = isfavorite;
                        masterVideoModel.setFavorite(currentVideoID, currentVideoFavorite);
                    }
                    states: [
                        State {
                            name: "showVideoToolbar"
                            when: showVideoToolbar
                            PropertyChanges {
                                target: videoToolbar
                                height: window.videoToolbarHeight
                                opacity:1
                            }
                        },
                        State {
                            name: "hideVideoToolbar"
                            when: !showVideoToolbar
                            PropertyChanges {
                                target: videoToolbar
                                height: 0
                                opacity: 0
                            }
                        }
                    ]

                    transitions: [
                        Transition {
                            reversible: true
                            ParallelAnimation{
                                PropertyAnimation {
                                    target:videoToolbar
                                    property: "height"
                                    duration: 250

                                }

                                PropertyAnimation {
                                    target: videoToolbar
                                    property: "opacity"
                                    duration: 250
                                }
                            }
                        }
                    ]
                }
            }
            TopItem { id: topItem }
        }
    }
}

