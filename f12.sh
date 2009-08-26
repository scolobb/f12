#!/bin/bash
#
# Creates a terminal with a screen session and focuses/unfocuses it on
# further invocations.
#
# WARNING: This script should be invoked *before* any other instances
# of gnome-terminal are launched! Otherwise you might get unexpected
# behaviour.

#------------------------------------------------------------------------------
# USER CONFIGURABLE VARIABLES
# ===========================

# The name of a gnome-terminal window class.
CLASS="gnome-terminal.Gnome-terminal"

# The command to execute in the terminal.
COMMAND="screen -D -RR"

# The command to launch the terminal.
TERMINAL="gnome-terminal -e"

# The time to wait for the terminal to start (in seconds).
WAIT_INTERVAL=0.5

# We will store the hex ID of the terminal window in this file.
CTRL_FILE="/tmp/f12-id"
#------------------------------------------------------------------------------

if [ ! -f $CTRL_FILE  ]
then
    # This is the first invocation.
    $TERMINAL "$COMMAND" &
    sleep $WAIT_INTERVAL

    # Store the hex ID of the new gnome-terminal window.
    WINDOW_ID=$(wmctrl -xl | grep "$CLASS" | cut -f1 -d " ")
    echo $WINDOW_ID > $CTRL_FILE

    # Make the window sticky.
    wmctrl -b add,sticky -i -r $WINDOW_ID

    exit 0
fi

# Retrieve the hex ID of the managed window.
WINDOW_ID=$(cat $CTRL_FILE)

if [ ! $(wmctrl -l | cut -d" " -f1 | grep $WINDOW_ID) ]
then
    # Our control file has gone stale -- there are no windows with the
    # ID we memorized at the first invocation.
    rm $CTRL_FILE
    f12.sh &
    exit 0
fi

ACTIVE_WINDOW_ID=$(xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)"\
 | cut -d"#" -f2)

# The stored window ID is of the format 0x[0-9a-f]{8}.  xprop does not
# bother outputting exactly 8 hex digits, so drop the leading 0x0* in
# both terms.
TRIMMED_ACTIVE_WINDOW_ID=$(echo $ACTIVE_WINDOW_ID | sed "s/0x0*//i")
TRIMMED_WINDOW_ID=$(echo $WINDOW_ID | sed "s/0x0*//i")
if [ "$TRIMMED_ACTIVE_WINDOW_ID" == "$TRIMMED_WINDOW_ID" ]
then
    # The managed window is the active window.  Hide it.
    wmctrl -b add,hidden,skip_taskbar -i -r $WINDOW_ID
else
    # Make sure the window is visible and bring to front.
    wmctrl -b remove,hidden,skip_taskbar -i -r $WINDOW_ID
    wmctrl -i -R $WINDOW_ID
fi
