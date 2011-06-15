import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Media 0.1
import QtMultimediaKit 1.1
import MeeGo.App.Video.VideoPlugin 1.0
import MeeGo.Sharing 0.1
import MeeGo.Sharing.UI 0.1
import "functions.js" as Code

AppPage {
    id: detailPage
    anchors.fill: parent
    property bool infocus: true
    property bool showVideoToolbar: false
    onActivated : {
        infocus = true;
        currentState.page = 1;
    }
    onDeactivated : { infocus = false; }

    function playvideo(fullscreen) // set the video up with the targetState
    {
        if(targetState.uri != "")
        {
            var itemid = masterVideoModel.datafromURI(targetState.uri, MediaItem.ID);

            if(itemid != "")
            {
                if(fullscreen)
                    Code.enterFullscreen();
                videoThumbnailView.hide();
                if(video.source != targetState.uri)
                {
                    videoThumbnailView.currentIndex = masterVideoModel.itemIndex(itemid);
                    video.source = videoThumbnailView.currentItem.muri;
                }
                Code.startFromPosition(targetState.command);
            }
        }
        else
        {
            Code.startFromPosition(targetState.command);
        }
    }

    ModalDialog {
        id: deleteItemDialog
        title: labelDelete
        acceptButtonText: labelConfirmDelete
        cancelButtonText: labelCancel
        onAccepted: {
            masterVideoModel.destroyItemByID(videoThumbnailView.currentItem.mitemid);
        }
        content: Item {
            id: contentItem
            anchors.fill: parent
            clip: true
            Text{
                id: titleText
                text : videoThumbnailView.currentItem.mtitle
                anchors.top: parent.top
                width:  parent.width
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                //: Confirmation message for deleting videos. "This" and "it" refer to the currently playing video which is onscreen.
                text: qsTr("If you delete this, it will be removed from your device")
                anchors.top:titleText.bottom
                width:  parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: theme_fontPixelSizeMedium
            }
        }
    }

    Connections {
        target: window
        onSetState: {
            if(infocus)
            {
                if(targetState.filter >= 0)
                    masterVideoModel.filter = targetState.filter;

                if(targetState.page == 0) // Goto LandingPage
                {
                    window.popPage();
                }
                else // Goto DetailPage
                {
                    detailPage.playvideo(true);
                }
            }
        }
    }

    Connections {
        target: resourceManager
        onStartPlaying: {
            if(infocus)
                video.play();
        }
        onStopPlaying: {
            if(infocus)
                video.pause();
        }
    }

    ContextMenu {
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
                    shareObj.addItem(video.source) // URI
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
            detailPage.lockOrientationIn = "landscape";
            detailPage.playvideo(true);
        }

        Component.onDestruction: {
            detailPage.lockOrientationIn = "noLock";
            editorModel.setPlayStatus(videoThumbnailView.currentItem.mitemid, VideoListModel.Stopped);
        }

        MediaPreviewStrip {
            id: videoThumbnailView
            model: masterVideoModel
            width: parent.width
            showText: false
            itemSpacing: 0
            anchors.top: parent.top
            anchors.topMargin: window.statusBar.height + detailPage.toolbarHeight
            anchors.horizontalCenter: parent.horizontalCenter
            z: 1000
            onClicked: {
                Code.playNewVideo(payload);
            }
        }
        states: [
            State {
                name: "showtoolbar-mode"
                when: !fullScreen
                PropertyChanges {
                    target: videoThumbnailView
                    anchors.topMargin: window.statusBar.height + detailPage.toolbarHeight
                }
            },
            State {
                name: "hidetoolbar-mode"
                when: fullScreen
                PropertyChanges {
                    target: videoThumbnailView
                    anchors.topMargin: 0
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
            anchors.fill: parent
            color: "black"
            Video {
                id: video
                anchors.bottom: parent.bottom
                width: screenWidth
                height: screenHeight
                autoLoad: true
                onStopped: {
                    Code.changestatus(VideoListModel.Stopped);
                    videoThumbnailView.show(true);
                    if(fullScreen)
                        Code.exitFullscreen();
                }
                onError: {
                    Code.changestatus(VideoListModel.Stopped);
                    //: This is the error text for a video that failed to play
                    info.text = qsTr("Sorry we are unable to play this content.")
                    info.show()
                }
                onPositionChanged: {
                    currentState.position = video.position;
                }
                onSourceChanged: {
                    detailPage.pageTitle = masterVideoModel.datafromURI(video.source, MediaItem.Title);
                    currentState.urn = masterVideoModel.datafromURI(video.source, MediaItem.URN);
                    currentState.uri = video.source;
                }
                Connections {
                    target: window
                    onIsActiveWindowChanged: {
                        if (!window.isActiveWindow && video.playing && !video.paused)
                        {
                            if (fullScreen)
                                Code.exitFullscreen();
                            Code.pause();
                        }
                    }
                }
            }
            InfoBar {
                id: info
                // TODO check visuals
                width: parent.width - 2*20
                anchors.horizontalCenter: parent.horizontalCenter
            }
            MouseArea {
                anchors.fill:parent
                onClicked:{
                    if(fullScreen)
                        Code.exitFullscreen();
                    else
                        Code.enterFullscreen();
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
        }

        MediaToolbar {
            id: videoToolbar
            anchors.bottom: parent.bottom
            width: parent.width
            opacity: 0
            height: 0
            showprev: true
            showplay: true
            shownext: true
            showprogressbar: true
            showvolume: true
            showfavorite: true
            isfavorite: videoThumbnailView.currentItem.mfavorite
            onPrevPressed: {
                Code.playPrevVideo();
                currentState.prevPressed();
            }
            onPlayPressed: Code.play();
            onPausePressed: Code.pause();
            onNextPressed: {
                Code.playNextVideo();
                currentState.nextPressed();
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
                currentState.sliderMoved(video.duration * videoToolbar.sliderPosition);
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
                masterVideoModel.setFavorite(videoThumbnailView.currentItem.mitemid, isfavorite);
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
