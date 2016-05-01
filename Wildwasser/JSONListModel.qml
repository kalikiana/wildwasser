/*
 * Copyright (C) 2016 Christian Dywan <christian@twotoasts.de>
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

import QtQuick 2.4

ListModel {
    property bool autoFetch: true
    // URL
    property var headers: {}
    property string method: 'GET'
    property var data
    property url source: ''
    onSourceChanged: {
        if (!source)
            return
        json = ''
        if (autoFetch)
            fetch()
    }

    // String
    property string json: ''
    onJsonChanged: {
        if (!json)
            return
        url = ''
        if (autoFetch)
            fetch()
    }

    // Results
    property var responseHeaders
    function getResponseHeader(header) {
        return xhr.getResponseHeader(header)
    }
    property var rows

    property string query
    property string subQuery
    property var roles
    signal fetched()
    signal failed(string error)
    property string errorString

    // Internal
    property var xhr

    function fetch() {
        if (json != '')
            return parse(json)

        if (source == '')
            return

        if (xhr)
            xhr.abort()

        xhr = new XMLHttpRequest()
        xhr.url = source
        xhr.open('POST', xhr.url, true)
        for (var header in headers) {
            xhr.setRequestHeader(header, headers[header])
        }
        xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded')

        xhr.onreadystatechange = function() {
            if (xhr.readyState == xhr.DONE) {
                if (xhr.status == 200) {
                    parse(xhr.responseText)
                    errorString = ''
                } else {
                    errorString = i18n.tr("Failed to fetch %1 (HTTP %2): %3")
                        .arg(xhr.url).arg(xhr.status).arg(xhr.responseText)
                    failed(errorString)
                }
                responseHeaders = xhr.getAllResponseHeaders()
            }
        }
        // console.log(JSON.stringify(data))
        xhr.send(JSON.stringify(data))
    }

    function parse(text) {
        var json = text
        try {
            json = JSON.parse(text)
        } catch (e) {
            failed("Failed to parse %1\n: %2".arg(text).arg(e.message))
        }
        // console.log('Parsing: %1'.arg(JSON.stringify(json)))
        if (json[query])
            json = json[query]
        if (json[subQuery])
            json = json[subQuery]
        try {
            loaded(json)
        } catch (e) {
            failed("Failed to add to model from %1\n: %2".arg(JSON.stringify(json)).arg(e.message))
        }
    }

    function loaded(json) {
        // console.log('JSON: %1'.arg(JSON.stringify(json)))
        clear()
        for (var index in json) {
            var item = json[index]
            // Basic types can't be added to the model: rows must be used
            if (typeof item === 'object')
                append(item)
        }
        rows = json
        fetched()
    }
}
