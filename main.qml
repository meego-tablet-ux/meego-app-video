/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import QtMultimediaKit 1.1
import MeeGo.Labs.Components 0.1
import MeeGo.Media 0.1
import MeeGo.Sharing 0.1

import "functions.js" as Code

Window {
    id: scene
    title: qsTr("Video")
    showsearch: false
    filterModel: []
    applicationPage: landingScreenContent
    filterMenuWidth: 300

    property string topicAll: qsTr("All")
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

    Timer {
        id: startupTimer
        interval: 2000
        repeat: false
    }

    Component.onCompleted: {
        startupTimer.start();
    }

    function enterFullscreen()
    {
        showtoolbar = false;
        showVideoToolbar = false;
        fullscreen = true;
    }

    function exitFullscreen()
    {
        fullscreen = false;
        showVideoToolbar = true;
        showtoolbar = true;
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
            console.log("Item Available: " + identifier);
            applicationData = ["video", identifier];
        }
    }

    Connections {
        target: mainWindow
        onCall: {
            console.log("Global onCall: " + parameters);
            if(parameters[0] == "orientation")
                orientation = (orientation+1)%4;
            else if(parameters[0] == "video")
                masterVideoModel.requestItem(parameters[1]);
            else if(parameters[0] == "pause")
                applicationData = parameters;
        }
    }

    Loader {
        id: volumeBarLoader
    }

    Component {
        id: volumeControlComponent
        VolumeController {
            onClose: {
                volumeBarLoader.sourceComponent = undefined;
            }
        }
    }

    Loader {
        anchors.fill: parent
        id: dialogLoader
    }

    Component {
        id: deleteItemComponent
        ModalDialog {
            dialogTitle: labelDelete
            leftButtonText: labelConfirmDelete
            rightButtonText:labelCancel
            property variant payload
            onPayloadChanged:{
                contentLoader.item.title = payload.mtitle;
            }

            onDialogClicked: {
                if( button == 1) {
                    console.log(payload.muri);
                    masterVideoModel.destroyItemByID(payload.mitemid);
                }
                dialogLoader.sourceComponent = undefined;
            }
            Component.onCompleted: {
                contentLoader.sourceComponent = dialogContent;
            }
            Component {
                id: dialogContent
                Item {
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
                        id:warning
                        text: qsTr("If you delete this, it will be removed from your device")
                        anchors.top:titleText.bottom
                        width:  parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: theme_fontPixelSizeMedium
                    }
                }
            }
        }
    }

    Component {
        id: deleteMultipleItemsComponent
        ModalDialog {
            property int deletecount: masterVideoModel.selectionCount()
            dialogTitle: (deletecount < 2)?qsTr("Permanently delete this video?"):qsTr("Permanently delete these %1 videos?").arg(deletecount)
            leftButtonText: labelConfirmDelete
            rightButtonText:labelCancel
            onDialogClicked: {
                if( button == 1) {
                    masterVideoModel.destroyItemsByID(masterVideoModel.getSelectedIDs());
                    masterVideoModel.clearSelected();
                    multibar.sharing.clearItems();
                    multiSelectMode = false;
                }
                dialogLoader.sourceComponent = undefined;
            }
            Component.onCompleted: {
                contentLoader.sourceComponent = dialogContent;
            }
            Component {
                id: dialogContent
                Item {
                    anchors.fill: parent
                    clip: true
                    Text {
                        id:warning
                        text: qsTr("If you delete these, they will be removed from your device")
                        anchors.verticalCenter:parent.verticalCenter
                        width:  parent.width
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: theme_fontPixelSizeMedium
                    }
                }
            }
        }
    }

    Component {
        id: landingScreenContent
        ApplicationPage {
            id: landingPage
            anchors.fill: parent
            title: qsTr("Videos")

            function playvideo(payload)
            {
                videoIndex = payload.mindex;
                currentVideoID = payload.mitemid;
                currentVideoFavorite = payload.mfavorite;
                videoSource = payload.muri;
                fullscreen = true;
                labelVideoTitle = payload.mtitle;
                editorModel.setViewed(payload.mitemid);
                editorModel.setPlayStatus(payload.mitemid, VideoListModel.Playing);
                landingPage.addApplicationPage(detailViewContent);
            }

            onSearch: {
                videoSearch = needle;
                landingItem.landingScreenGridView.opacity = 0;
                masterVideoModel.search = videoSearch;
                if(masterVideoModel.filter != VideoListModel.FilterSearch)
                    masterVideoModel.filter = VideoListModel.FilterSearch
                videoListState = (videoListState + 1)%2;
            }

            onApplicationDataChanged: {
                if(applicationData != undefined)
                {
                    console.log("Remote Call: " + applicationData);
                    var cmd = applicationData[0];
                    var cdata = applicationData[1];

                    scene.applicationData = undefined;
                    console.log("in landing screen");

                    if (cmd == "video")
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
                            console.log("URI: " + uri);
                            videoSource = uri;
                            fullscreen = false;
                            labelVideoTitle = title;
                            landingPage.addApplicationPage(detailViewContent);
                            editorModel.setViewed(itemid);
                            editorModel.setPlayStatus(itemid, VideoListModel.Playing);
                        }
                    }
                }
            }

            ShareObj {
                id: shareObj
                shareType: MeeGoUXSharingClientQmlObj.ShareTypeVideo
            }

            ContextMenu {
                id: contextMenu
                onTriggered: {
                    shareObj.clearItems();
                    if (model[index] == labelPlay)
                    {
                        // Play
                        landingPage.playvideo(payload);
                    }
                    else if ((model[index] == labelFavorite)||(model[index] == labelUnFavorite))
                    {
                        // Favorite/unfavorite
                        Code.changeItemFavorite(payload);
                    }
                    else if (model[index] == labelDelete)
                    {
                        // Delete
                        scene.showModalDialog(deleteItemComponent);
                        dialogLoader.item.payload = payload;
                    }
                    else if (model[index] == labelMultiSelect)
                    {
                        // multi select mode on
                        multiSelectMode = true;
                    }
                    else if (model[index] == labelcShare)
                    {
                        // Share
                        shareObj.clearItems();
                        shareObj.addItem(payload.muri) // URI
                        shareObj.showContextTypes(mouseX, mouseY)
                    }
                }
            }
            property int highlightindex: 0
            menuContent: Column {
                width: childrenRect.width
                ActionMenu {
                    model: [topicAll, qsTr("Recently added"), qsTr("Recently viewed"), qsTr("Unwatched"), qsTr("Favorites")]
                    title: qsTr("Filter By")
                    highlightIndex: highlightindex
                    onTriggered: {
                        highlightindex = index;
                        if (index == 0) {
                            landingScreenGridView.opacity = 0;
                            if(masterVideoModel.filter != VideoListModel.FilterAll)
                            {
                                masterVideoModel.filter = VideoListModel.FilterAll
                                masterVideoModel.sort = VideoListModel.SortByTitle;
                            }
                        }else if( index == 1) {
                            landingScreenGridView.opacity = 0;
                            if(masterVideoModel.filter != VideoListModel.FilterAdded)
                            {
                                masterVideoModel.filter = VideoListModel.FilterAdded
                                masterVideoModel.sort = VideoListModel.SortByAddedTime;
                            }
                        }else if(index == 2) {
                            landingScreenGridView.opacity = 0;
                            if(masterVideoModel.filter != VideoListModel.FilterViewed)
                            {
                                masterVideoModel.filter = VideoListModel.FilterViewed
                                masterVideoModel.sort = VideoListModel.SortByAccessTime;
                            }
                        }else if(index == 3) {
                            landingScreenGridView.opacity = 0;
                            if(masterVideoModel.filter != VideoListModel.FilterUnwatched)
                            {
                                masterVideoModel.filter = VideoListModel.FilterUnwatched
                                masterVideoModel.sort = VideoListModel.SortByTitle;
                            }
                        }else if(index == 4) {
                            landingScreenGridView.opacity = 0;
                            if(masterVideoModel.filter != VideoListModel.FilterFavorite)
                            {
                                masterVideoModel.filter = VideoListModel.FilterFavorite
                                masterVideoModel.sort = VideoListModel.SortByTitle;
                            }
                        }else if(index == 5) {
                            landingScreenGridView.opacity = 0;
                            masterVideoModel.search = videoSearch;
                            if(masterVideoModel.filter != VideoListModel.FilterSearch)
                            {
                                masterVideoModel.filter = VideoListModel.FilterSearch
                                masterVideoModel.sort = VideoListModel.SortByTitle;
                            }
                        }
                        videoListState = (videoListState + 1)%2;
                        landingPage.closeMenu()
                    }
                }
            }

            Item {
                id: landingItem
                parent: landingPage.content
                anchors.fill: parent
                Component.onCompleted: {
                    if(currentVideoID != "")
                        editorModel.setPlayStatus(currentVideoID, VideoListModel.Stopped);
                    showsearch = true;
                    videoVisible = false;
                    fullscreen = false;
                    showtoolbar = true;
                    showVideoToolbar = false;
                }

                Item {
                    id: noVideosScreen
                    anchors.centerIn: parent
                    height: parent.height/2
                    width: (scene.isLandscapeView())?(parent.width/2):(parent.width/1.2)
                    visible: ((masterVideoModel.total == 0)&&(!startupTimer.running))
                    Text {
                        id: noVideosScreenText1
                        width: parent.width
                        text: qsTr("No videos added yet, do you want to start watching videos?")
                        font.pixelSize: scene.height/17
                        anchors.top: parent.top
                        wrapMode: Text.WordWrap
                    }
                    Text {
                        id: noVideosScreenText2
                        width: parent.width
                        text: qsTr("Start recording your own or upload your favourite shows.")
                        font.pixelSize: scene.height/21
                        anchors.top: noVideosScreenText1.bottom
                        anchors.topMargin: scene.height/24
                        wrapMode: Text.WordWrap
                    }
                }

                MediaGridView {
                    id: landingScreenGridView
                    type: videotype // video app = 0
                    selectionMode: multiSelectMode
                    clip:true
                    opacity: 0
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.topMargin:3
                    cellWidth:(width- 15) / (scene.isLandscapeView() ? 7: 4)
                    cellHeight: cellWidth
                    model: masterVideoModel
                    defaultThumbnail: "image://theme/media/video_thumb_med"
                    onClicked:{
                        if(multiSelectMode)
                        {
                            masterVideoModel.setSelected(payload.mitemid, !masterVideoModel.isSelected(payload.mitemid));
                            if (masterVideoModel.isSelected(payload.mitemid))
                                multibar.sharing.addItem(payload.muri);
                            else
                                multibar.sharing.delItem(payload.muri);
                        }
                        else
                        {
                            videoIndex = payload.mindex;
                            currentVideoID = payload.mitemid;
                            currentVideoFavorite = payload.mfavorite;
                            videoSource = payload.muri;
                            fullscreen = false;
                            labelVideoTitle = payload.mtitle;
                            landingPage.addApplicationPage(detailViewContent);
                            editorModel.setViewed(payload.mitemid);
                            editorModel.setPlayStatus(payload.mitemid, VideoListModel.Playing);
                        }
                    }
                    onLongPressAndHold: {
                        if(!multiSelectMode)
                        {
                            var map = payload.mapToItem(scene, mouseX, mouseY);
                            contextMenu.model = [labelPlay, ((payload.mfavorite)?labelUnFavorite:labelFavorite),
                                                 labelcShare, labelMultiSelect, labelDelete];
                            contextMenu.payload = payload;
                            contextMenu.menuX = map.x;
                            contextMenu.menuY = map.y;
                            contextMenu.visible = true;
                        }
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
        }
    }  

    Component {
        id: detailViewContent
        ApplicationPage {
            id: detailPage
            anchors.fill: parent
            title: labelVideoTitle
            fullContent: true
            showSearch: false
            disableSearch: true

            function playvideo(payload)
            {
                console.log("playvideo " + payload.mtitle);
                currentVideoID = payload.mitemid;
                currentVideoFavorite = payload.mfavorite;
                videoSource = payload.muri;
                labelVideoTitle = payload.mtitle;
                editorModel.setViewed(payload.mitemid);
                editorModel.setPlayStatus(payload.mitemid, VideoListModel.Playing);

                videoToolbar.ispause = true;
                video.source = videoSource;
                video.play();
                if(fullscreen)
                    showVideoToolbar = false;
                else
                    showVideoToolbar = true;
                videoVisible = true;
            }

            onApplicationDataChanged: {
                if(applicationData != undefined)
                {
                    console.log("Remote Call: " + applicationData);
                    var cmd = applicationData[0];
                    var cdata = applicationData[1];

                    scene.applicationData = undefined;
                    console.log("in detail mode");

                    if (cmd == "video")
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
                                showtoolbar = false;
                                showVideoToolbar = false;
                                fullscreen = true;
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
                    else if (cmd == "pause")
                    {
                        videoToolbar.ispause = false;
                        if(video.playing)
                            video.pause();
                    }
                }
            }
            ShareObj {
                id: shareObj
                shareType: MeeGoUXSharingClientQmlObj.ShareTypeVideo
            }
            ContextMenu {
                id: contextMenu
                onTriggered: {
                    shareObj.clearItems();
                    if (model[index] == qsTr("Delete"))
                    {
                        // Delete
                        deleteitem(currentVideoID);
                    }
                    else
                    {
                        // Share
                        shareObj.addItem(videoSource);
                        var svcTypes = shareObj.serviceTypes;
                        for (x in svcTypes) {
                            if (model[index] == svcTypes[x]) {
                                shareObj.showContext(model[index], menuX, menuY);
                                break;
                            }
                        }
                    }
                }
            }
            Item {
                id: detailItem
                parent: detailPage.content
                anchors.fill: parent

                property alias videoThumbList: videoThumbnailView

                function lockedOrientation() {
                    var newOrientation = 1
                    //console.log("current orientation is " + scene.orientation)
                    //console.log("current width is " + scene.width)
                    //console.log("current height is " + scene.height)

                    // on netbook width > height, so orientation must be 1
                    if (scene.width <= scene.height)
                        newOrientation = 2

                    return newOrientation
                }
                
                Component.onCompleted: {
                    scene.orientation = lockedOrientation();
                    scene.orientationLocked = true;
                    showsearch = false;
                    video.source = videoSource;
                    video.play();
                    if(fullscreen)
                        showVideoToolbar = false;
                    else
                        showVideoToolbar = true;
                    videoVisible = true;
                }

                Component.onDestruction: {
                    scene.orientationLocked = false;
                }

                MediaPreviewStrip {
                    id: videoThumbnailView
                    model: masterVideoModel
                    width: parent.width
                    showText: false
                    itemSpacing: 0
                    anchors.top: parent.top
                    anchors.topMargin: 5 + scene.statusBar.height + detailPage.toolbarHeight
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
                        when: showtoolbar
                        PropertyChanges {
                            target: videoThumbnailView
                            anchors.topMargin: 5 + scene.statusBar.height + detailPage.toolbarHeight
                        }
                    },
                    State {
                        name: "hidetoolbar-mode"
                        when: !showtoolbar
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
                        height: ((parent.width * 3)/4) * (parent.height/scene.height)
                        width: parent.width
                        autoLoad: true
                        onStopped: {
                            editorModel.setPlayStatus(currentVideoID, VideoListModel.Stopped);
                            videoThumbnailView.show(true);
                            if(fullscreen)
                                exitFullscreen();
                        }
                        onError: {
                        }

                        Component.onDestruction: {
                            console.log("Video object being destroyed");
                        }

                        Connections {
                            target: scene
                            onForegroundChanged: {
                                if (!scene.foreground && video.playing && !video.paused)
                                {
                                    if (fullscreen)
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
                            if(fullscreen)
                            {
                                fullscreen = false;
                                showVideoToolbar = true;
                                showtoolbar = true;
                            }
                            else
                            {
                                showtoolbar = false;
                                showVideoToolbar = false;
                                fullscreen = true;
                            }
                            videoVisible = true;
                            videoThumbnailView.hide();
                        }
                        onPressAndHold: {
                            var map = mapToItem(scene, mouseX, mouseY);
                            var ctxList = shareObj.serviceTypes;
                            contextMenu.model = ctxList.concat(qsTr("Delete"));
                            contextMenu.menuX = map.x;
                            contextMenu.menuY = map.y;
                            contextMenu.visible = true;
                        }
                    }

                    states: [
                        State {
                            name: "VideoLandscape"
                            when: videoVisible&&!videoCropped&&scene.isLandscapeView()
                            PropertyChanges {
                                target: videorect
                                width: detailPage.content.width;
                                height: detailPage.content.height;
                            }
                            PropertyChanges {
                                target: video
                                height: detailPage.content.height;
                            }
                        },
                        State {
                            name: "VideoPortrait"
                            when: videoVisible&&!videoCropped&&!scene.isLandscapeView()
                            PropertyChanges {
                                target: videorect
                                width: detailPage.content.width;
                                height: detailPage.content.height;
                            }
                            PropertyChanges {
                                target: video
                                height: detailPage.content.height;
                            }
                        },
                        State {
                            name: "VideoLandscapeCropped"
                            when: videoVisible&&videoCropped&&scene.isLandscapeView()
                            PropertyChanges {
                                target: videorect
                                width: detailPage.content.width;
                                height: detailPage.content.height;
                            }
                        },
                        State {
                            name: "VideoPortraitCropped"
                            when: videoVisible&&videoCropped&&!scene.isLandscapeView()
                            PropertyChanges {
                                target: videorect
                                width: detailPage.content.width;
                                height: detailPage.content.height;
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
                                height: scene.videoToolbarHeight
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
        }
    }

    MediaMultiBar {
        id: multibar
        parent:  content
        height: (multiSelectMode)?55:0
        width: parent.width
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        landscape: scene.isLandscapeView()
        showadd: false
        onCancelPressed: {
            sharing.clearItems();
            masterVideoModel.clearSelected();
            multiSelectMode = false;
        }
        onDeletePressed: {
            if(masterVideoModel.selectionCount() > 0)
                scene.showModalDialog(deleteMultipleItemsComponent);
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
}

