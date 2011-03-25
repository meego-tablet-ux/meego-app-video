/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

function changeItemFavorite(item) {
    editorModel.setFavorite(item.mitemid,!item.mfavorite)
}

function playNextVideo() {
    if (contentStrip.activeContent.videoThumbList.currentIndex < (contentStrip.activeContent.videoThumbList.count -1))
    {
        contentStrip.activeContent.videoThumbList.currentIndex++;
        currentVideoID = contentStrip.activeContent.videoThumbList.currentItem.mitemid;
        currentVideoFavorite = contentStrip.activeContent.videoThumbList.currentItem.mfavorite;
    }
    else
    {
        contentStrip.activeContent.videoThumbList.currentIndex = 0;
        currentVideoID = "";
        currentVideoFavorite = false;
    }

    playNewVideo(contentStrip.activeContent.videoThumbList.currentItem);
}

function playPrevVideo() {
    if (contentStrip.activeContent.videoThumbList.currentIndex == 0)
    {
        contentStrip.activeContent.videoThumbList.currentIndex = contentStrip.activeContent.videoThumbList.count - 1;
        currentVideoID = "";
        currentVideoFavorite = false;
    }
    else
    {
        contentStrip.activeContent.videoThumbList.currentIndex--;
        currentVideoID = contentStrip.activeContent.videoThumbList.currentItem.mitemid;
        currentVideoFavorite = contentStrip.activeContent.videoThumbList.currentItem.mfavorite;
    }
    playNewVideo(contentStrip.activeContent.videoThumbList.currentItem);
}

function formatTime(time)
{
    var min = parseInt(time/60);
    var sec = parseInt(time%60);
    return min+ (sec<10 ? ":0":":") + sec
}

function formatMinutes(time)
{
    var min = parseInt(time/60);
    return min
}

function openItemInDetailView(item)
{
    videoSource = item.muri;
    videoFullscreen = false;
//    contentStrip.push(detailViewContent,videosSideContent);
    landingPage.addApplicationPage(detailViewContent);
//    contentStrip.activeContent.crumb.label = item.mtitle;
    labelVideoTitle = item.mtitle;
    editorModel.setViewed(item.mitemid);
}

function openItemInDetailViewFullscreen(item)
{
    videoSource = item.muri;
    videoFullscreen = true;
    scene.fullscreen = true;
    contentStrip.push(detailViewContent,videosSideContent);
    contentStrip.activeContent.crumb.label = item.mtitle;
    labelVideoTitle = item.mtitle;
    editorModel.setViewed(item.mitemid);
}
