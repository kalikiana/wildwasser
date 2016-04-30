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
import Ubuntu.Components 1.3
import Qt.labs.settings 1.0

Page {
    id: torrentsPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Wildwasser")
        flickable: torrentsList
    }

    property int lastSelectedIndex: -1
    property var lastSelectedPage: null

    Timer {
        interval: 1500
        running: window.active
        repeat: running
        onTriggered: torrents.fetch()
    }

    Settings {
        id: settings
        property string server: '127.0.0.1:9091'
    }

    UbuntuListView {
        id: torrentsList
        anchors.fill: parent
        model: JSONListModel {
            id: torrents
            // curl -v -H 'X-Transmission-Session-Id: Cjv1cnCuVvy2oR0JdF83uNeduiX2KwNcbxo0JdlP0mmttmMZ' -d '{"arguments":{"fields":["name"]},"method":"torrent-get"}' http://localhost:9091/transmission/rpc
            // https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
            source: 'http://%1/transmission/rpc'.arg(settings.server)
            method: 'PUT'
            query: 'arguments'
            subQuery: 'torrents'
            property string sessionToken
            onResponseHeadersChanged: {
                var newSessionToken = getResponseHeader('X-Transmission-Session-ID')
                if (newSessionToken && newSessionToken != sessionToken) {
                    // Session token changed? Try once more
                    headers = { 'X-Transmission-Session-ID': newSessionToken }
                    sessionToken = newSessionToken
                    fetch()
                }
            }
            onFetched: {
                if (lastSelectedIndex > -1 && lastSelectedPage) {
                    lastSelectedPage.model = torrents.get(lastSelectedIndex)
                    // console.log(JSON.stringify(rows[lastSelectedIndex]))
                }
            }

            data: {
                "arguments": {
                    "fields": [
                        // Used in the list
                        "name", "errorString", "totalSize", "percentDone", "rateDownload", "rateUpload", "isFinished", "eta",
                        // Used in the details
                        "files", "wanted"
                    ]
                },
                "method": "torrent-get"
            }
        }

        // Error display
        UbuntuShape {
            anchors.centerIn: parent
            width: parent.width / 1.5
            height: parent.height / 3
            color: theme.palette.normal.overlay
            Label {
                anchors.fill: parent
                text: torrents.errorString
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
            Row {
                Label {
                    text: i18n.tr('Server')
                }

                TextField {
                    text: settings.server
                    onTextChanged: settings.server = text
                }
            }
            visible: torrents.errorString
        }

        delegate: ListItem {
            function size(fraction) {
                if (fraction > Math.pow(10, 9))
                    return i18n.tr('%1 GB'.arg(Number(fraction / Math.pow(10, 9)).toFixed(1)))
                if (fraction > Math.pow(10, 6))
                    return i18n.tr('%1 MB'.arg(Number(fraction / Math.pow(10, 6)).toFixed(1)))
                return i18n.tr('%1 kB'.arg(Number(fraction / Math.pow(10, 3)).toFixed(1)))
            }

            height: listItemLayout.height + divider.height
            ListItemLayout {
                id: listItemLayout
                title.text: name
                title.maximumLineCount: 2
                property string timeLeft: {
                    if (eta < 0)
                        return i18n.tr('Unknown')
                    var date = new Date()
                    date.setSeconds(eta)
                    return i18n.relativeDateTime(date)
                }
                subtitle.text: errorString ? errorString : i18n.tr('⬇ %1 ⬆ %2 ⏱ %3').arg(size(rateDownload)).arg(size(rateUpload)).arg(timeLeft)
                subtitle.color: errorString ? theme.palette.normal.negative : theme.palette.normal.activity
                ProgressBar {
                    value: percentDone
                    width: listItemLayout.width / 3
                    visible: !isFinished && !errorString
                    enabled: !errorString
                    showProgressPercentage: false
                    Label {
                        anchors.centerIn: parent
                        text: i18n.tr('%1 of %2').arg(size(totalSize * percentDone)).arg(size(totalSize))
                    }
                }
            }
            onClicked: {
                lastSelectedIndex = index
                lastSelectedPage = null
                var incubator = pageLayout.addPageToNextColumn(torrentsPage, Qt.resolvedUrl('TorrentDetails.qml'), { 'model': model })
                if (incubator/* && incubator.status == Component.Loading*/) {
                    incubator.onStatusChanged = function(status) {
                        if (status == Component.Ready) {
                            lastSelectedPage = incubator.object
                        }
                    }
                }
            }
        }
    }
}
