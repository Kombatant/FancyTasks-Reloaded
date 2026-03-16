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
    readonly property bool badgeDebugEnabled: appName === "Viber"
        || appName === "Zen Browser"
        || appId.toLowerCase() === "viber"
        || appId.toLowerCase() === "zen"
    property bool isActiveWindow: false
    property int revision: 0
    property int syntheticIdCounter: 0
    property var liveNotificationIds: ({})
    property int eventUnreadCount: 0
    readonly property var taskAliases: aliasesForTask()
    readonly property int count: {
        revision;
        const unread = unreadCount();
        const live = liveNotificationCount();
        const total = Math.max(unread, live, eventUnreadCount);
        if (badgeDebugEnabled) {
            console.log("[fancytasks_badge][SmartLauncher] recalc",
                        "appName=", appName,
                        "appId=", appId,
                        "launcherUrl=", String(launcherUrl),
                        "taskAliases=", JSON.stringify(taskAliases),
                        "unreadCount=", unread,
                        "liveNotificationCount=", live,
                        "eventUnreadCount=", eventUnreadCount,
                        "result=", total,
                        "notificationsModel.count=", notificationsModel.count);
        }
        return total;
    }
    readonly property bool countVisible: count > 0
    property bool urgent: countVisible
    property bool progressVisible: false
    property real progress: 0

    NotificationManager.Notifications {
        id: notificationsModel
        showNotifications: true
        showJobs: false
        showExpired: false
        showDismissed: false
        groupMode: NotificationManager.Notifications.GroupDisabled
        sortMode: NotificationManager.Notifications.SortByDate
    }

    Connections {
        target: notificationsModel
        function onCountChanged() { smartLauncher.revision++; }
        function onDataChanged() { smartLauncher.revision++; }
        function onRowsInserted(parent, first, last) {
            smartLauncher.recordInsertedNotifications(first, last);
            smartLauncher.revision++;
        }
        function onRowsRemoved() { smartLauncher.revision++; }
        function onModelReset() { smartLauncher.revision++; }
        function onUnreadNotificationsCountChanged() { smartLauncher.revision++; }
        function onLastReadChanged() { smartLauncher.revision++; }
    }

    Connections {
        target: NotificationManager.Server
        function onNotificationAdded(notification) {
            smartLauncher.trackLiveNotification(notification);
        }
        function onNotificationReplaced(replacedId, notification) {
            smartLauncher.untrackLiveNotification(replacedId);
            smartLauncher.trackLiveNotification(notification);
        }
        function onNotificationRemoved(id) {
            smartLauncher.untrackLiveNotification(id);
        }
    }

    onLauncherUrlChanged: revision++
    onAppIdChanged: revision++
    onAppNameChanged: revision++
    onIsActiveWindowChanged: {
        if (isActiveWindow) {
            liveNotificationIds = ({});
            eventUnreadCount = 0;
            if (badgeDebugEnabled) {
                console.log("[fancytasks_badge][SmartLauncher] resetBecauseActive",
                            "appName=", appName,
                            "appId=", appId);
            }
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

        const dottedParts = key.split(".");
        if (dottedParts.length > 1) {
            add(dottedParts[dottedParts.length - 1]);
        }

        const dashedParts = key.split("-");
        if (dashedParts.length > 1) {
            add(dashedParts[dashedParts.length - 1]);
        }

        const underscoredParts = key.split("_");
        if (underscoredParts.length > 1) {
            add(underscoredParts[underscoredParts.length - 1]);
        }

        return aliases;
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

        const normalizedAppName = normalizeKey(appName);
        const normalizedAppId = normalizeKey(appId);
        const normalizedLauncher = normalizeKey(launcherUrl);
        const looksLikeZen = normalizedAppName.indexOf("zen") !== -1
            || normalizedAppId.indexOf("zen") !== -1
            || normalizedLauncher.indexOf("zen") !== -1;

        if (looksLikeZen) {
            addAll(aliasesForValue("firefox"));
            addAll(aliasesForValue("mozilla-firefox"));
            addAll(aliasesForValue("firefox-esr"));
        }

        return aliases;
    }

    function aliasesForNotification(notification) {
        const aliases = [];

        function addAll(values) {
            for (let i = 0; i < values.length; ++i) {
                const value = values[i];
                if (value && aliases.indexOf(value) === -1) {
                    aliases.push(value);
                }
            }
        }

        if (!notification) {
            return aliases;
        }

        addAll(aliasesForValue(notification.desktopEntry));
        addAll(aliasesForValue(notification.applicationName));
        addAll(aliasesForValue(notification.applicationIconName));

        return aliases;
    }

    function debugNotification(prefix, notification, extra) {
        const parts = [
            "[fancytasks_badge]",
            prefix,
            "launcherUrl=", String(launcherUrl),
            "appId=", appId,
            "appName=", appName,
            "taskAliases=", JSON.stringify(taskAliases)
        ];

        if (notification) {
            parts.push("desktopEntry=", String(notification.desktopEntry));
            parts.push("applicationName=", String(notification.applicationName));
            parts.push("applicationIconName=", String(notification.applicationIconName));
            parts.push("notifAliases=", JSON.stringify(aliasesForNotification(notification)));
            if (notification.id !== undefined) {
                parts.push("id=", String(notification.id));
            }
            if (notification.notificationId !== undefined) {
                parts.push("notificationId=", String(notification.notificationId));
            }
        }

        if (extra !== undefined) {
            parts.push("extra=", JSON.stringify(extra));
        }

        console.log(parts.join(" "));
    }

    function notificationObjectId(notification) {
        if (!notification) {
            return 0;
        }

        if (notification.id !== undefined && notification.id !== null) {
            return Number(notification.id);
        }

        if (notification.notificationId !== undefined && notification.notificationId !== null) {
            return Number(notification.notificationId);
        }

        syntheticIdCounter++;
        return -syntheticIdCounter;
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

    function trackLiveNotification(notification) {
        const notificationAliases = aliasesForNotification(notification);
        const matches = matchesAliases(notificationAliases);
        if (badgeDebugEnabled || matches) {
            debugNotification("trackLiveNotification", notification, {
                matches: matches,
                eventUnreadCount: eventUnreadCount,
                liveNotificationCount: liveNotificationCount()
            });
        }

        if (!matches) {
            return;
        }

        const id = notificationObjectId(notification);
        if (!id) {
            return;
        }

        const updated = Object.assign({}, liveNotificationIds);
        updated[String(id)] = true;
        liveNotificationIds = updated;
        eventUnreadCount++;
        if (badgeDebugEnabled) {
            debugNotification("tracked", notification, {
                eventUnreadCount: eventUnreadCount,
                liveNotificationCount: liveNotificationCount()
            });
        }
        revision++;
    }

    function untrackLiveNotification(id) {
        const key = String(id);
        if (!liveNotificationIds[key]) {
            return;
        }

        const updated = Object.assign({}, liveNotificationIds);
        delete updated[key];
        liveNotificationIds = updated;
        if (badgeDebugEnabled) {
            console.log("[fancytasks_badge][SmartLauncher] untrackLiveNotification id=", key,
                        "eventUnreadCount=", eventUnreadCount,
                        "liveNotificationCount=", liveNotificationCount());
        }
        revision++;
    }

    function liveNotificationCount() {
        return Object.keys(liveNotificationIds).length;
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

    function notificationIsUnread(index) {
        if (notificationsModel.data(index, NotificationManager.Notifications.TypeRole)
                !== NotificationManager.Notifications.NotificationType) {
            return false;
        }

        if (notificationsModel.data(index, NotificationManager.Notifications.ReadRole)
                || notificationsModel.data(index, NotificationManager.Notifications.ExpiredRole)
                || notificationsModel.data(index, NotificationManager.Notifications.DismissedRole)) {
            return false;
        }

        return true;
    }

    function recordInsertedNotifications(first, last) {
        if (taskAliases.length === 0) {
            return;
        }

        let matched = 0;

        for (let row = first; row <= last; ++row) {
            const index = notificationsModel.index(row, 0);
            if (!notificationIsUnread(index)) {
                continue;
            }

            const matches = notificationMatches(index);
            if (!matches) {
                if (badgeDebugEnabled) {
                    console.log("[fancytasks_badge][SmartLauncher] unmatchedInsertedNotification",
                                "appName=", appName,
                                "appId=", appId,
                                "row=", row,
                                "desktopEntry=", notificationsModel.data(index, NotificationManager.Notifications.DesktopEntryRole),
                                "applicationName=", notificationsModel.data(index, NotificationManager.Notifications.ApplicationNameRole),
                                "applicationIconName=", notificationsModel.data(index, NotificationManager.Notifications.ApplicationIconNameRole),
                                "originName=", notificationsModel.data(index, NotificationManager.Notifications.OriginNameRole),
                                "summary=", notificationsModel.data(index, NotificationManager.Notifications.SummaryRole));
                }
                continue;
            }

            matched++;
        }

        if (matched <= 0) {
            return;
        }

        eventUnreadCount += matched;
        if (badgeDebugEnabled) {
            console.log("[fancytasks_badge][SmartLauncher] recordInsertedNotifications",
                        "appName=", appName,
                        "appId=", appId,
                        "rows=", first, "-", last,
                        "matched=", matched,
                        "eventUnreadCount=", eventUnreadCount);
        }
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
