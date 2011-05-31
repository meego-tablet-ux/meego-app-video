import Qt 4.7
import MeeGo.Components 0.1
import MeeGo.Media 0.1
import QtMultimediaKit 1.1
import MeeGo.App.Video.VideoPlugin 1.0
import MeeGo.Sharing 0.1
import MeeGo.Sharing.UI 0.1
import "functions.js" as Code

AppPage {
    id: landingPage
    anchors.fill: parent
    pageTitle: labelAppName
    property bool infocus: true

    onActivated : {
        infocus = true;
        if(currentVideoID != "")
            editorModel.setPlayStatus(currentVideoID, VideoListModel.Stopped);
        window.disableToolBarSearch = false;
        window.fullScreen = false;
        window.lockOrientationIn = "noLock";
        fullScreen = false;
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
        window.fullScreen = true;
        labelVideoTitle = payload.mtitle;
        window.addPage(detailViewContent);
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
                        itemid = masterVideoModel.datafromURN(cdata, MediaItem.ID);
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
                        fullScreen = false;
                        labelVideoTitle = title;
                        window.addPage(detailViewContent);
                    }
                }
            }
        }
    }

    ContextMenu {
        id: contextMenu
        property alias payload: contextActionMenu.payload
        property alias model: contextActionMenu.model
        property int mouseX
        property int mouseY
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
                    shareObj.showContextTypes(contextMenu.mouseX, contextMenu.mouseY)
                }
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
            width: (window.isLandscape)?(parent.width/2):(parent.width/1.2)
            visible: ((masterVideoModel.total == 0)&&(!startupTimer.running))
            Text {
                id: noVideosScreenText1
                width: parent.width
                text: qsTr("No videos have been added. Do you want to start watching videos?")
                font.pixelSize: window.height/17
                anchors.top: parent.top
                wrapMode: Text.WordWrap
            }
            Text {
                id: noVideosScreenText2
                width: parent.width
                text: qsTr("Start recording or upload your favorite shows.")
                font.pixelSize: window.height/21
                anchors.top: noVideosScreenText1.bottom
                anchors.topMargin: window.height/24
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            id: globalbgsolid
            anchors.fill: parent
            color: "black"
        }

        BorderImage {
            id: panel
            anchors.fill: parent
            anchors.topMargin: 8
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.bottomMargin: 5
            source: "image://themedimage/widgets/apps/media/assets/content-background"
            border.left:   8
            border.top:    8
            border.bottom: 8
            border.right:  8
        }

        MediaGridView {
            id: landingScreenGridView
            type: videotype // video app = 0
            selectionMode: multiSelectMode
            showHeader: true
            clip:true
            opacity: 0
            anchors.fill: parent
            anchors.topMargin: 10
            anchors.bottomMargin: 10
            anchors.leftMargin: (parent.width - Math.floor(parent.width / 370)*370) / 2
            anchors.rightMargin: anchors.leftMargin
            model: masterVideoModel
            defaultThumbnail: "image://themedimage/images/media/video_thumb_med"
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
                    fullScreen = false;
                    labelVideoTitle = payload.mtitle;
                    window.addPage(detailViewContent);
                }
            }
            onLongPressAndHold: {
                if(!multiSelectMode)
                {
                    var map = payload.mapToItem(topItem.topItem, mouseX, mouseY);
                    contextMenu.model = [labelPlay, ((payload.mfavorite)?labelUnFavorite:labelFavorite),
                                         labelcShare, labelMultiSelect, labelDelete];
                    contextMenu.payload = payload;
                    contextMenu.mouseX = map.x;
                    contextMenu.mouseY = map.y;
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
            landscape: window.isLandscape
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
                    shareObj.showContextTypes(map.x, map.y)
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
    }
    TopItem { id: topItem }
}
