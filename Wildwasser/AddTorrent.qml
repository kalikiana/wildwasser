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
    id: addPage
    header: PageHeader {
        id: pageHeader

        title: i18n.tr("Add torrent")

        leadingActionBar {
            actions: [
            Action {
                iconName: "back"
                text: i18n.tr('Cancel')
                onTriggered: layout.removePages(addPage)
            }
            ]
        }

        trailingActionBar {
            actions: [
                Action {
                    id: confirmAction

                    enabled: false
                    visible: enabled
                    iconName: "ok"
                    text: i18n.tr('Confirm')
                    onTriggered: {
                        enabled = false
                        addTorrent.fetch()
                    }
                }
            ]
            //            delegate: pageHeader.delegate
        }
    }

    Settings {
        id: settings
        property string server: '127.0.0.1:9091'
    }

    JSONListModel {
        id: addTorrent
        // curl -v -H 'X-Transmission-Session-Id: Cjv1cnCuVvy2oR0JdF83uNeduiX2KwNcbxo0JdlP0mmttmMZ' -d '{"arguments":{"filename", "foo.torrent"},"method":"torrent-add"}' http://localhost:9091/transmission/rpc
        // https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt
        autoFetch: false
        source: 'http://%1/transmission/rpc'.arg(settings.server)
        method: 'PUT'
        // query: 'arguments'
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
        data: {
            "arguments": {
                "filename": urlField.text,
                "paused": false
            },
            "method": "torrent-add"
        }
        onFetched: {
            // console.log('Rows: %1'.arg(JSON.stringify(rows)))
            if (rows.arguments['torrent-added'])
                layout.removePages(addPage)
        }
    }

    Column {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height / 2
        spacing: units.gu(4)
        Label {
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            elide: Text.ElideMiddle
            width: parent.width
            text: {
                var matches = urlField.text.match(/([?&]title=)([^&]+)/)
                return matches && matches.length == 3 ? matches[2].toString() : urlField.text
            }
        }
        Row {
            spacing: units.gu(2)
            width: parent.width
            Label {
                text: i18n.tr('File')
                width: parent.width / 3
                height: urlField.height
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
            TextField {
                id: urlField
                width: parent.width / 2
                onTextChanged: confirmAction.enabled = text.indexOf('://') > -1
                placeholderText: i18n.tr('http://www.example.com/example.torrent')
            }
        }
        // Error display
        UbuntuShape {
            x: parent.spacing
            width: parent.width - parent.spacing * 2
            color: theme.palette.normal.overlay
            Label {
                width: parent.width / 1.5
                anchors.centerIn: parent
                text: {
                    if (!addTorrent.rows)
                        return i18n.tr('Insert the URL of a torrent file')
                    var args = addTorrent.rows.arguments
                    return addTorrent.errorString ||
                            (args && args['torrent-duplicate'] ?
                                 i18n.tr('Torrent %1 is already in the list').arg(args['torrent-duplicate'].name) :
                                 i18n.tr('Torrent %1 was successfully added').arg(args['torrent-added'].name))
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
            }
        }
    }
}

