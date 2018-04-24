#!/bin/bash
# This script is launched at the login of the user "kiosk"
# to detect its inactivity and restart the session

# Settings
# IDLE_TIME: Idle time before locking, in MINUTES
# LOCK_CMD : program used to lock. Killing session.
# NOTIFY   : notify this many SECONDS before locking.
# NOTIFIER : program used to notify.


CONFIGFILE="${HOME}/.autolock"

# Print the given message with a timestamp.
info() { printf '%s\t%s\n' "$(date)" "$*"; }

log() {
    if [ -n "${LOCK_LOG:-}" ]; then
        info >>"$LOCK_LOG" "$@"
    else
        info "$@"
    fi
}

xautolock_cmd() {
    log "Launching xautolock ..."
    if [ -z "${NOTIFIER}" ]; then
      xautolock -time $IDLE_TIME -locker "$LOCK_CMD"
    else
      xautolock -time $IDLE_TIME -locker "$LOCK_CMD" -notify $NOTIFY -notifier "$NOTIFIER > /dev/null 2>&1"
    fi
}

# Main
if [ -f "${CONFIGFILE}" ]; then
  . "${CONFIGFILE}"
else
  log "Config file not found"
  exit 1
fi

if [ -z "${IDLE_TIME}" -o -z "${LOCK_CMD}" ]; then
  log "Parameters IDLE_TIME or LOCK_CMD not configured"
  exit 1
fi

xautolock_cmd
