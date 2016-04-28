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

MainView {
    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "wildwasser.kalikiana"

    width: units.gu(100)
    height: units.gu(75)

    AdaptivePageLayout {
        id: pageLayout
        anchors.fill: parent
        primaryPageSource: Qt.resolvedUrl('TorrentList.qml')
    }
}
