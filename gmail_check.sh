#!/bin/bash
# This script gets GMail unread emails and notifies the user of their presence
# Requires: curl [google app password]

#######################################################################################################################
##### CONFIGURABLE SETTINGS - ADJUST AS NEEDED
#
# authentication info (using app password - https://support.google.com/accounts/answer/185833?hl=en)
U="YYYYYYYY@gmail.com"
P="zzzz zzzz zzzz zzzz"
#######################################################################################################################

# get new mail subjects and put into an array
mapfile -t new_mail < <( curl -u "$U:$P" --silent "https://mail.google.com/mail/feed/atom" |  grep -oPm1 "(?<=<title>)[^<]+" | sed '1d' )

# determine number of new items
COUNT=$(echo ${#new_mail[@]})

# prepare notification and content
NOTIF=$(cat /tmp/.gmail-notif)
[[ -z $NOTIF ]] && NOTIF=1
ICON=mail-unread
TITLE="You have unread Gmail"

if [ $COUNT -gt 0 ]; then
    # prepare the tooltip with subject lines
    for (( x=0; x<$COUNT; x++ ))
    do
        TOOLTIP+=">\t ${new_mail[$x]}\r"
    done

    # if there is new email, send a notification, replacing/updating existing notification
    # https://gist.github.com/kiosion/40d71f765cbad0be95ae308418b83c3a
    gdbus call \
        --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        -- \
        "identifier" \
        "$(echo $NOTIF)" \
        "$(echo $ICON)" \
        "$(echo $TITLE)" \
        "$(echo $TOOLTIP)" \
        "[]" \
        "{}" \
        "20000" \
    | sed 's/[^ ]* //; s/,.//' > /tmp/.gmail-notif
else
    # clear any existing notification bubble, since no unread emails exist
    gdbus call \
        --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.CloseNotification \
        "$(echo $NOTIF)"
fi

exit 0

~/.config/systemd/user/gmail.service
------------------------------------
[Unit]
Description=Check for unread GMail
After=network.target
[Service]
Type=oneshot
ExecStart=/home/toz/.local/bin/gmail_check.sh
[Install]
WantedBy=default.target

~/.config/systemd/user/gmail.timer
----------------------------------
[Unit]
Description=Display unread GMail in bubble every 10 minutes
[Timer]
Unit=gmail.service
OnBootSec=3min
OnUnitActiveSec=10m
[Install]
WantedBy=timers.target

#systemctl --user enable gmail.timer --now
