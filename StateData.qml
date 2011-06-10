/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7

Item {
    id: content
    // control parameters
    property int page: -1
    property string uri: ""
    property int position: -1
    property string command: ""
    property int filter: -1

    // status paramaters
    property string urn: ""
    signal prevPressed();
    signal nextPressed();

    function clear()
    {
        page = -1;
        uri = "";
        position = -1;
        command = "";
        filter = -1;
    }

    function set(n_page, n_command, n_uri, n_position, n_filter)
    {
        page = n_page;
        command = n_command;
        uri = n_uri;
        position = n_position;
        filter = n_filter;
    }
}
