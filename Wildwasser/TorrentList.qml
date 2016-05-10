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
        trailingActionBar.actions: [
            Action {
                iconName: 'list-add'
                onTriggered: pageLayout.addPageToNextColumn(torrentsPage, Qt.resolvedUrl('AddTorrent.qml'))
            },
            Action {
                // Toggle test data
                shortcut: 'Ctrl+Shift+T'
                onTriggered: torrents.json = JSON.stringify(mockTorrentsModel)
            }
        ]
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

    property var mockTorrentsModel: [
        {
            "errorString": "No local files found. Check that all volumes are mounted.",
            "eta": -1,
            "files": [
                {
                    "bytesCompleted": 9813213,
                    "length": 2801482973,
                    "name": "My.Favorite.Series.S01E01.720p.HDTV.x264.mkv"
                }
            ],
            "isFinished": false,
            "name": "My.Favorite.Series.S01E01.720p.HDTV.x264.mkv",
            "percentDone": 0.0035,
            "rateDownload": 0,
            "rateUpload": 0,
            "totalSize": 2801482973,
            "wanted": [1]
        },
        {
            "errorString": "",
            "eta": 634,
            "files": [
                {
                    "bytesCompleted": 168,
                    "length": 168,
                    "name": "My.Other.Favorite.Series.S01E01.HDTV.x264-FOO[bar]/READ.ME.PLEASE.KTHXBYE.txt"
                },
                {
                    "bytesCompleted": 41642142,
                    "length": 359590046,
                    "name": "My.Other.Favorite.Series.S01E01.HDTV.x264-FOO[bar]/my.other.favorite.series.s01e01.hdtv.x264-foo[bar].mp4"
                }
            ],
            "isFinished": false,
            "name": "My.Other.Favorite.Series.S01E01.HDTV.x264-FOO[bar]",
            "percentDone": 0.1158,
            "rateDownload": 602000,
            "rateUpload": 2000,
            "totalSize": 359590214,
            "wanted": [1, 1]
        },
        {
            "errorString": "",
            "eta": 3526,
            "files": [
                {
                    "bytesCompleted": 23805952,
                    "length": 1485881344,
                    "name": "ubuntu-16.04-desktop-amd64.iso"
                }
            ],
            "isFinished": false,
            "name": "ubuntu-16.04-desktop-amd64.iso",
            "percentDone": 0.016,
            "rateDownload": 437000,
            "rateUpload": 0,
            "totalSize": 1485881344,
            "wanted": [1]
        },
        {
            "errorString": "unregistered torrent",
            "eta": 1076,
            "files": [
                {
                    "bytesCompleted": 81224738,
                    "length": 928670754,
                    "name": "Big_Buck_Bunny_1080p_surround_frostclick.com_frostwire.com/Big_Buck_Bunny_1080p_surround_FrostWire.com.avi"},
                {
                    "bytesCompleted": 5008,
                    "length": 5008,
                    "name": "Big_Buck_Bunny_1080p_surround_frostclick.com_frostwire.com/PROMOTE_YOUR_CONTENT_ON_FROSTWIRE_01_06_09.txt"
                },
                {
                    "bytesCompleted": 572650,
                    "length": 3456234,
                    "name": "Big_Buck_Bunny_1080p_surround_frostclick.com_frostwire.com/Pressrelease_BickBuckBunny_premiere.pdf"
                },
                {
                    "bytesCompleted": 180,
                    "length": 180,
                    "name": "Big_Buck_Bunny_1080p_surround_frostclick.com_frostwire.com/license.txt"
                }
            ],
            "isFinished":false,
            "name": "Big_Buck_Bunny_1080p_surround_frostclick.com_frostwire.com",
            "percentDone": 0.088,
            "rateDownload": 747000,
            "rateUpload": 0,
            "totalSize": 932132176,
            "wanted": [1,1,0,0]
        }
    ]

    UbuntuListView {
        id: torrentsList
        focus: true

        anchors {
            top: errorColumn.visible ? errorColumn.bottom : parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true

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

        delegate: ListItem {
            function size(fraction) {
                if (fraction > Math.pow(10, 9))
                    return i18n.tr('%1 GB'.arg(Number(fraction / Math.pow(10, 9)).toFixed(1)))
                if (fraction > Math.pow(10, 6))
                    return i18n.tr('%1 MB'.arg(Number(fraction / Math.pow(10, 6)).toFixed(1)))
                return i18n.tr('%1 kB'.arg(Number(fraction / Math.pow(10, 3)).toFixed(1)))
            }

            height: column.height + units.gu(1) + divider.height

            Column {
                id: column

                width: parent.width

                ListItemLayout {
                    id: listItemLayout

                    title.text: name
                    property string timeLeft: {
                        if (eta < 0)
                            return i18n.tr('Unknown')
                        var date = new Date()
                        date.setSeconds(eta)
                        return i18n.relativeDateTime(date)
                    }
                    subtitle.text: errorString ? errorString : i18n.tr('⬇ %1  ⬆ %2  ⏱ %3').arg(size(rateDownload)).arg(size(rateUpload)).arg(timeLeft)
                    subtitle.color: errorString ? theme.palette.normal.negative : theme.palette.normal.activity
                    subtitle.maximumLineCount: 10
                    padding.bottom: units.gu(.5)
                    padding.top: units.gu(1)
                }

                ProgressBar {
                    id: progress

                    value: percentDone
                    width: parent.width - units.gu(4)
                    height: progressLabel.height
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                    }
                    visible: !isFinished && !errorString
                    enabled: !errorString
                    showProgressPercentage: false
                    Label {
                        id: progressLabel
                        anchors.centerIn: parent
                        text: i18n.tr('%1 of %2').arg(size(totalSize * percentDone)).arg(size(totalSize))
                        textSize: Label.Small
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

    // Error display
    Column {
        id: errorColumn
        visible: torrents.errorString
        anchors {
            top: pageHeader.bottom
            topMargin: units.gu(2)
        }
        width: parent.width

        SlotsLayout {
            Label {
                text: i18n.tr("Server")
                anchors.verticalCenter: serverField.verticalCenter
                SlotsLayout.position: SlotsLayout.Leading
                SlotsLayout.overrideVerticalPositioning: true
            }

            mainSlot: TextField {
                id: serverField

                text: settings.server
                onTextChanged: settings.server = text
            }
        }

        SlotsLayout {
            Icon {
                color: UbuntuColors.red
                name: "dialog-warning-symbolic"
                width: units.gu(2)
                SlotsLayout.position: SlotsLayout.Leading
            }

            mainSlot: Label {
                id: errorLabel

                text: torrents.errorString
                wrapMode: Text.WordWrap
            }
        }
    }
}
