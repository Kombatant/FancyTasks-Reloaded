/*
    SPDX-FileCopyrightText: 2016 Kai Uwe Broulik <kde@privat.broulik.de>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick 2.15

import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Item {
    readonly property int iconWidthDelta: 0
    readonly property bool shiftBadgeDown: (plasmoid.configuration.iconOnly) && task.audioStreamIconLoaderItem.shown
    readonly property int badgeNumber: task.smartLauncherItem ? task.smartLauncherItem.count : 0
    readonly property bool badgeVisible: task.smartLauncherItem && task.smartLauncherItem.countVisible

    anchors.fill: parent
    z: 9999

    Rectangle {
        readonly property int offset: Math.round(Math.max(Kirigami.Units.smallSpacing / 2, parent.width / 20))
        id: badgeBubble
        anchors.right: Qt.application.layoutDirection === Qt.RightToLeft ? undefined : parent.right
        anchors.left: Qt.application.layoutDirection === Qt.RightToLeft ? parent.left : undefined
        anchors.top: parent.top
        anchors.topMargin: offset + (shiftBadgeDown ? Math.round(icon.height / 2) : 0)
        width: Math.max(Kirigami.Units.iconSizes.smallMedium, Math.round(parent.width * 0.42))
        height: width
        radius: width / 2
        color: "#ff1f1f"
        border.color: "#ffffff"
        border.width: Math.max(1, Math.round(Screen.devicePixelRatio))
        visible: badgeVisible

        PlasmaComponents3.Label {
            anchors.centerIn: parent
            color: "#ffffff"
            font.bold: true
            font.pointSize: 1024
            fontSizeMode: Text.Fit
            minimumPointSize: 6
            text: badgeNumber > 99 ? "99+" : badgeNumber.toString()
        }
    }
}
