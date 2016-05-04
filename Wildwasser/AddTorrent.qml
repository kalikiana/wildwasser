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
                    iconName: "close"
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
                    iconName: "ok"
                    text: i18n.tr('Confirm')
                    onTriggered: {
                        enabled = false
                        addTorrent.fetch()
                    }
                }
            ]
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
        anchors {
            top: pageHeader.bottom
            topMargin: units.gu(2)
        }
        width: parent.width

        Label {
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            elide: Text.ElideMiddle
            width: parent.width - units.gu(4)
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
            }
            text: {
                var matches = urlField.text.match(/([?&]title=)([^&]+)/)
                return matches && matches.length == 3 ? matches[2].toString() : urlField.text
            }
        }

        SlotsLayout {
            Label {
                text: i18n.tr("File")
                anchors.verticalCenter: urlField.verticalCenter
                SlotsLayout.position: SlotsLayout.Leading
                SlotsLayout.overrideVerticalPositioning: true
            }

            mainSlot: TextField {
                id: urlField

                onTextChanged: confirmAction.enabled = text.indexOf('://') > -1
                placeholderText: i18n.tr('http://www.example.com/example.torrent')
                inputMethodHints: Qt.ImhUrlCharactersOnly
            }
        }

        // Error display
        SlotsLayout {
            Icon {
                color: name === "dialog-warning-symbolic" ? UbuntuColors.red : errorLabel.color
                name: {
                    if (!addTorrent.rows)
                        return "info"
                    var args = addTorrent.rows.arguments
                    return addTorrent.errorString ||
                            (args && args['torrent-duplicate'] ?
                                 "dialog-warning-symbolic" :
                                 "ok")
                }
                width: units.gu(2)
                SlotsLayout.position: SlotsLayout.Leading
            }

            mainSlot: Label {
                id: errorLabel

                text: {
                    if (!addTorrent.rows)
                        return i18n.tr('Insert the URL of a torrent file')
                    var args = addTorrent.rows.arguments
                    return addTorrent.errorString ||
                            (args && args['torrent-duplicate'] ?
                                 i18n.tr('Torrent %1 is already in the list').arg(args['torrent-duplicate'].name) :
                                 i18n.tr('Torrent %1 was successfully added').arg(args['torrent-added'].name))
                }
                wrapMode: Text.WordWrap
            }
        }
    }
}

