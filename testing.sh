#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_ID="org.kombatant.fancytasks_rld"
PACKAGE_PATH="$SCRIPT_DIR/package"
LOCAL_PACKAGE_DIR="$HOME/.local/share/plasma/plasmoids/$PACKAGE_ID"

run_kpackagetool() {
	err_file=$(mktemp)
	if kpackagetool6 "$@" 2>"$err_file"; then
		exit_code=0
	else
		exit_code=$?
	fi

	grep -F -v 'does not match requested format "Plasma/Applet"' "$err_file" >&2 || true
	rm -f "$err_file"
	return "$exit_code"
}

if ! run_kpackagetool --type Plasma/Applet --upgrade "$PACKAGE_PATH"; then
	run_kpackagetool --type Plasma/Applet --remove "$PACKAGE_ID" >/dev/null 2>&1 || true
	rm -rf "$LOCAL_PACKAGE_DIR"
	run_kpackagetool --type Plasma/Applet --install "$PACKAGE_PATH"
fi

QML_DISABLE_DISK_CACHE=true plasmawindowed "$PACKAGE_ID"
