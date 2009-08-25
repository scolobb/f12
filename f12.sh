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

# The maximal allowed Z-index for our window.  If the window is found
# to have a Z-index less than this value while visible, it is brought
# to front.
MAX_Z_INDEX=1

# This command will be used to retrieve the list of currently open
# window sorted by Z-index.
#
# WARNING: This is very dependent on the formatting of the output of
# xwininfo, so please be ready to broken functionality after updates.
#
# WARNING: This is very dependent on the window manager you are using.
# This command works under GNOME/OpenBox 3.4.7.2.
#
# EXPLANATION: This command asks xwininfo to list all the children of
# the root window.  Most visible windows appear indented by 8 spaces.
# Then comes the hex ID of the window.  Visible windows have the IDs
# of length 7 or longer.  Then we drop the "(has no name)" windows,
# which appear under GNOME.
LIST_WINDOWS_BY_Z="xwininfo -root -tree \
| grep -E \"^\ \ \ \ \ \ \ \ 0x[0-9a-f]{7,}\" | grep -v \"has no name\""
#------------------------------------------------------------------------------

if [ ! -f $CTRL_FILE  ]
then
    # This is the first invocation.
    $TERMINAL "$COMMAND" &
    sleep $WAIT_INTERVAL

    # Store the hex ID of the new gnome-terminal window.
    WINDOW_ID=$(wmctrl -xl | grep "$CLASS" | cut -f1 -d " ")
    echo $WINDOW_ID > $CTRL_FILE
    echo "visible" >> $CTRL_FILE

    # Hide the window from taskbar and make it sticky.
    wmctrl -b add,skip_taskbar -i -r $WINDOW_ID
    wmctrl -b add,sticky -i -r $WINDOW_ID

    exit 0
fi

# Retrieve the hex ID and the state of the managed window.
WINDOW_ID=$(head -n1 $CTRL_FILE)
WINDOW_STATE=$(tail -n1 $CTRL_FILE)

if [ ! $(wmctrl -l | cut -d" " -f1 | grep $WINDOW_ID) ]
then
    # Our control file has gone stale -- there are no windows with the
    # ID we memorized at the first invocation.
    rm $CTRL_FILE
    f12.sh &
    exit 0
fi

# Construct the contents of $CTRL_FILE anew.
echo $WINDOW_ID > $CTRL_FILE

if [ $WINDOW_STATE = "visible" ]
then
    # xwininfo does not bother outputting exactly 8 hex digits, so
    # drop the 0x and the possible leading zeroes.
    WINDOW_ID_TRIMMED=$(echo $WINDOW_ID | sed "s/0x0*//i")

    # Get the Z-index of the managed window.
    Z_INDEX=$(eval $LIST_WINDOWS_BY_Z | grep -n $WINDOW_ID_TRIMMED \
	| cut -d":" -f1)

    if [ $Z_INDEX -le $MAX_Z_INDEX ]
    then
	# The window is visible and currently on top.  Hide it.
	wmctrl -b add,hidden -i -r $WINDOW_ID
    else
	# The window is visible, but not on top.  Bring it to front.
	wmctrl -i -R $WINDOW_ID
    fi

    WINDOW_STATE="hidden"
else
    WINDOW_STATE="visible"

    # Show the window.
    wmctrl -b remove,hidden -i -r $WINDOW_ID

    # Bring the terminal window to front.
    wmctrl -i -R $WINDOW_ID
fi
echo $WINDOW_STATE >> $CTRL_FILE
