/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

function forceState(data)
{
    var items = data.split(",");
    var page = parseInt(items[0]);
    var cmd = items[1];
    var identifier = items[2];
    var position = parseInt(items[3]);
    var filter = parseInt(items[4]);

    if((page != 0)&&(page != 1)&&(page != -1))
        return;
    if((cmd != "play")&&(cmd != "pause")&&(cmd != "stop")&&(cmd != ""))
        return;
    if((filter != VideoListModel.FilterAll)&&(filter != VideoListModel.FilterFavorite)&&
       (filter != VideoListModel.FilterViewed)&&(filter != VideoListModel.FilterAdded)&&
       (filter != VideoListModel.FilterUnwatched)&&(filter != -1))
        return;

    if(identifier != "")
    {
        targetState.set(page, cmd, "", position, filter);
        masterVideoModel.requestItem(identifier);
    } else {
        targetState.set(page, cmd, identifier, position, filter);
        window.setState();
    }
}

function getID(identifier)
{
    var itemid = "";

    if(masterVideoModel.isURN(identifier))
        itemid = masterVideoModel.datafromURN(identifier, MediaItem.ID);
    else
        itemid = identifier;

    return itemid;
}

function getData(identifier, role)
{
    if(masterVideoModel.isURN(identifier))
        return masterVideoModel.datafromURN(identifier, role);
    else
        return masterVideoModel.datafromID(identifier, role);
}

function enterFullscreen()
{
    showVideoToolbar = false;
    fullScreen = true;
}

function exitFullscreen()
{
    fullScreen = false;
    showVideoToolbar = true;
}

function changeItemFavorite(item) {
    editorModel.setFavorite(item.mitemid,!item.mfavorite)
}

function changestatus(videostate)
{
    if(videostate == VideoListModel.Playing)
    {
        // Play
        currentState.command = "play";
        editorModel.setPlayStatus(videoThumbnailView.currentItem.mitemid, VideoListModel.Playing);
        videoToolbar.ispause = true;
        window.inhibitScreenSaver = true;
    }
    else if(videostate == VideoListModel.Paused)
    {
        // Pause
        currentState.command = "pause";
        editorModel.setPlayStatus(videoThumbnailView.currentItem.mitemid, VideoListModel.Paused);
        videoToolbar.ispause = false;
        window.inhibitScreenSaver = false;
    }
    else
    {
        // Stop
        currentState.command = "stop";
        editorModel.setPlayStatus(videoThumbnailView.currentItem.mitemid, VideoListModel.Stopped);
        videoToolbar.ispause = false;
        window.inhibitScreenSaver = false;
    }
}

function play()
{
    if (!video.playing || video.paused)
    {
        resourceManager.userwantsplayback = true;
        changestatus(VideoListModel.Playing);
        editorModel.setViewed(videoThumbnailView.currentItem.mitemid);
    }
}

function pause()
{
    video.pause();
    resourceManager.userwantsplayback = false;
    changestatus(VideoListModel.Paused);
}

function stop()
{
    video.stop();
    resourceManager.userwantsplayback = false;
    changestatus(VideoListModel.Stopped);
}

function startFromPosition(command)
{
    if((targetState.position >= 0)&&(targetState.position != video.position))
        video.position = targetState.position;

    if(command == "play")
        play();
    else if(command == "pause")
        pause();
    else if(command == "stop")
        stop();
}

function playNewVideo(payload)
{
    videoToolbar.isfavorite = videoThumbnailView.currentItem.mfavorite;
    editorModel.setViewed(payload.mitemid);

    videoToolbar.ispause = true;
    video.source = payload.muri;
    play();
    if(fullScreen)
        showVideoToolbar = false;
    else
        showVideoToolbar = true;
}

function playNextVideo() {
    videoThumbnailView.show(true);
    if (videoThumbnailView.currentIndex < (videoThumbnailView.count -1))
        videoThumbnailView.currentIndex++;
    else
        videoThumbnailView.currentIndex = 0;

    playNewVideo(videoThumbnailView.currentItem);
}

function playPrevVideo() {
    videoThumbnailView.show(false);
    if (videoThumbnailView.currentIndex == 0)
        videoThumbnailView.currentIndex = videoThumbnailView.count - 1;
    else
        videoThumbnailView.currentIndex--;

    playNewVideo(videoThumbnailView.currentItem);
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

function videoCheck(cdata)
{
    // if the video ends in .desktop, it's not a video
    return (cdata.indexOf(".desktop", cdata.length - 8) == -1);
}
