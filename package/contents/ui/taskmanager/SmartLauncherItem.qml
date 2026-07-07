import QtQuick 2.15

import org.kde.notificationmanager as NotificationManager

Item {
    id: smartLauncher

    visible: false
    width: 0
    height: 0

    property url launcherUrl
    property string appId: ""
    property string appName: ""
    property bool isActiveWindow: false
    property int revision: 0
    // Notifications older than this are considered "seen"; bumped when the
    // task's window becomes active so the badge clears on activation.
    property double lastClearedTime: 0
    readonly property var taskAliases: aliasesForTask()
    readonly property int count: {
        revision;
        return unreadCount();
    }
    readonly property bool countVisible: count > 0
    property bool urgent: countVisible
    property bool progressVisible: false
    property real progress: 0

    NotificationManager.Notifications {
        id: notificationsModel
        showNotifications: true
        showJobs: false
        // Expired notifications (popup timed out) must stay countable —
        // otherwise the badge would silently drop even though the user
        // never saw or dismissed the notification.
        showExpired: true
        showDismissed: false
        groupMode: NotificationManager.Notifications.GroupDisabled
        sortMode: NotificationManager.Notifications.SortByDate
    }

    Connections {
        target: notificationsModel
        function onCountChanged() { smartLauncher.revision++; }
        function onDataChanged() { smartLauncher.revision++; }
        function onRowsInserted() { smartLauncher.revision++; }
        function onRowsRemoved() { smartLauncher.revision++; }
        function onModelReset() { smartLauncher.revision++; }
        function onUnreadNotificationsCountChanged() { smartLauncher.revision++; }
        function onLastReadChanged() { smartLauncher.revision++; }
    }

    onLauncherUrlChanged: revision++
    onAppIdChanged: revision++
    onAppNameChanged: revision++
    onIsActiveWindowChanged: {
        if (isActiveWindow) {
            lastClearedTime = Date.now();
            revision++;
        }
    }

    function normalizeKey(value) {
        if (value === undefined || value === null) {
            return "";
        }

        let key = String(value).trim();
        if (!key) {
            return "";
        }

        key = key.replace(/^applications:/, "");
        key = key.replace(/^file:\/\//, "");

        const queryIndex = key.indexOf("?");
        if (queryIndex !== -1) {
            key = key.slice(0, queryIndex);
        }

        const fragmentIndex = key.indexOf("#");
        if (fragmentIndex !== -1) {
            key = key.slice(0, fragmentIndex);
        }

        const slashIndex = key.lastIndexOf("/");
        if (slashIndex !== -1) {
            key = key.slice(slashIndex + 1);
        }

        key = key.replace(/\.desktop$/i, "");
        return key.trim().toLowerCase();
    }

    function aliasesForValue(value) {
        const aliases = [];
        const key = normalizeKey(value);

        function add(alias) {
            if (alias && aliases.indexOf(alias) === -1) {
                aliases.push(alias);
            }
        }

        if (!key) {
            return aliases;
        }

        add(key);
        add(key.replace(/[^a-z0-9]/g, ""));

        // Reverse-DNS ids ("org.kde.dolphin") also match on their last
        // component. Dash/underscore tails are deliberately NOT used: they
        // produce generic words ("browser", "manager") that cross-match
        // unrelated applications.
        const dottedParts = key.split(".");
        if (dottedParts.length > 1) {
            add(dottedParts[dottedParts.length - 1]);
        }

        return aliases;
    }

    function keyLooksLikeZen(key) {
        if (!key) {
            return false;
        }

        if (key === "zen" || key === "zen-browser" || key === "zenbrowser") {
            return true;
        }

        if (key.indexOf("zen_browser") !== -1 || key.indexOf("zen-browser") !== -1) {
            return true;
        }

        const dottedParts = key.split(".");
        return dottedParts[dottedParts.length - 1] === "zen";
    }

    function aliasesForTask() {
        const aliases = [];

        function addAll(values) {
            for (let i = 0; i < values.length; ++i) {
                const value = values[i];
                if (value && aliases.indexOf(value) === -1) {
                    aliases.push(value);
                }
            }
        }

        addAll(aliasesForValue(launcherUrl));
        addAll(aliasesForValue(appId));
        addAll(aliasesForValue(appName));

        const looksLikeZen = keyLooksLikeZen(normalizeKey(appName))
            || keyLooksLikeZen(normalizeKey(appId))
            || keyLooksLikeZen(normalizeKey(launcherUrl));

        if (looksLikeZen) {
            addAll(aliasesForValue("firefox"));
            addAll(aliasesForValue("mozilla-firefox"));
            addAll(aliasesForValue("firefox-esr"));
        }

        return aliases;
    }

    function matchesAliases(candidateAliases) {
        if (taskAliases.length === 0) {
            return false;
        }

        for (let i = 0; i < candidateAliases.length; ++i) {
            if (taskAliases.indexOf(candidateAliases[i]) !== -1) {
                return true;
            }
        }

        return false;
    }

    function notificationMatches(index) {
        const desktopEntryAliases = aliasesForValue(
            notificationsModel.data(index, NotificationManager.Notifications.DesktopEntryRole));
        const applicationNameAliases = aliasesForValue(
            notificationsModel.data(index, NotificationManager.Notifications.ApplicationNameRole));
        const applicationIconAliases = aliasesForValue(
            notificationsModel.data(index, NotificationManager.Notifications.ApplicationIconNameRole));
        const originNameAliases = aliasesForValue(
            notificationsModel.data(index, NotificationManager.Notifications.OriginNameRole));
        return matchesAliases(desktopEntryAliases)
            || matchesAliases(applicationNameAliases)
            || matchesAliases(applicationIconAliases)
            || matchesAliases(originNameAliases);
    }

    function notificationTimestamp(index) {
        const updated = notificationsModel.data(index, NotificationManager.Notifications.UpdatedRole);
        if (updated && !isNaN(updated.getTime()) && updated.getTime() > 0) {
            return updated.getTime();
        }

        const created = notificationsModel.data(index, NotificationManager.Notifications.CreatedRole);
        if (created && !isNaN(created.getTime())) {
            return created.getTime();
        }

        return 0;
    }

    function notificationIsUnread(index) {
        if (notificationsModel.data(index, NotificationManager.Notifications.TypeRole)
                !== NotificationManager.Notifications.NotificationType) {
            return false;
        }

        if (notificationsModel.data(index, NotificationManager.Notifications.ReadRole)
                || notificationsModel.data(index, NotificationManager.Notifications.DismissedRole)) {
            return false;
        }

        return notificationTimestamp(index) > lastClearedTime;
    }

    function unreadCount() {
        if (taskAliases.length === 0) {
            return 0;
        }

        let unread = 0;

        for (let row = 0; row < notificationsModel.count; ++row) {
            const index = notificationsModel.index(row, 0);
            if (!notificationIsUnread(index)) {
                continue;
            }

            if (notificationMatches(index)) {
                unread++;
            }
        }

        return unread;
    }
}
