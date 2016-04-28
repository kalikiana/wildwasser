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

Page {
    id: detailsPage
    property var model

    header: PageHeader {
        id: pageHeader
        title: model ? model.name : ''
        subtitle: model ? model.errorString : ''
        flickable: detailsList
    }

    UbuntuListView {
        id: detailsList
        model: detailsPage.model ? detailsPage.model.files : []
        anchors.fill: parent

        delegate: ListItem {
            function size(fraction) {
                if (fraction > Math.pow(10, 9))
                    return i18n.tr('%1 GB').arg(Number(fraction / Math.pow(10, 9)).toFixed(1))
                if (fraction > Math.pow(10, 6))
                    return i18n.tr('%1 MB').arg(Number(fraction / Math.pow(10, 6)).toFixed(1))
                return i18n.tr('%1 kB').arg(Number(fraction / Math.pow(10, 3)).toFixed(1))
            }

            height: listItemLayout.height + divider.height
            ListItemLayout {
                id: listItemLayout
                title.text: name
                title.maximumLineCount: 2
                CheckBox {
                    SlotsLayout.position: SlotsLayout.Leading
                    checked: detailsPage.model.wanted[index] ? true : !detailsPage.model.wanted.length
                    enabled: false
                }

                ProgressBar {
                    value: bytesCompleted
                    maximumValue: length
                    width: listItemLayout.width / 3
                    visible: value < maximumValue
                    showProgressPercentage: false
                    Label {
                        anchors.centerIn: parent
                        text: i18n.tr('%1 of %2').arg(size(bytesCompleted)).arg(size(length))
                    }
                }
            }
            onClicked: pageLayout.addPageToNextColumn(torrentsPage, Qt.resolvedUrl('TorrentDetails.qml'), { 'model': model })
        }
    }
}
