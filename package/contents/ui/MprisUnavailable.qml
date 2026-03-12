import QtQuick 2.15

QtObject {
    readonly property bool available: false

    function playerForLauncherUrl(launcherUrl, pid) {
        return null;
    }

    function isPlaying(player) {
        return false;
    }

    function isStopped(player) {
        return true;
    }

    function playerIconName(player, launcherUrl) {
        return "";
    }

    function goPrevious(player) {
    }

    function goNext(player) {
    }

    function play(player) {
    }

    function pause(player) {
    }

    function playPause(player) {
    }

    function stop(player) {
    }

    function raise(player) {
    }

    function quit(player) {
    }
}