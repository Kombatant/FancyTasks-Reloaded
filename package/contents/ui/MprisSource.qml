import QtQuick 2.15

import org.kde.plasma.private.mpris as Mpris

QtObject {
    id: root

    readonly property bool available: true
    readonly property Mpris.Mpris2Model model: Mpris.Mpris2Model {}

    function playerForLauncherUrl(launcherUrl, pid) {
        if (!launcherUrl || launcherUrl === "") {
            return null;
        }

        return model.playerForLauncherUrl(launcherUrl, pid || 0);
    }

    function isPlaying(player) {
        return !!player && player.playbackStatus === Mpris.PlaybackStatus.Playing;
    }

    function isStopped(player) {
        return !player || player.playbackStatus === Mpris.PlaybackStatus.Stopped;
    }

    function playerIconName(player, launcherUrl) {
        if (player && player.desktopEntry) {
            return player.desktopEntry;
        }

        if (!launcherUrl) {
            return "";
        }

        var desktopFileName = launcherUrl.toString().split('/').pop().split('?')[0].replace('.desktop', '');
        if (desktopFileName.indexOf('applications:') === 0) {
            desktopFileName = desktopFileName.substr(13);
        }

        return desktopFileName;
    }

    function goPrevious(player) {
        if (player) {
            player.Previous();
        }
    }

    function goNext(player) {
        if (player) {
            player.Next();
        }
    }

    function play(player) {
        if (player) {
            player.Play();
        }
    }

    function pause(player) {
        if (player) {
            player.Pause();
        }
    }

    function playPause(player) {
        if (player) {
            player.PlayPause();
        }
    }

    function stop(player) {
        if (player) {
            player.Stop();
        }
    }

    function raise(player) {
        if (player) {
            player.Raise();
        }
    }

    function quit(player) {
        if (player) {
            player.Quit();
        }
    }
}