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

# This is the expected title of the new terminal window.
TITLE="New screen..."

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
    WINDOW_ID=$(wmctrl -l | grep "$TITLE" | cut -f1 -d " ")
    echo $WINDOW_ID > $CTRL_FILE
    echo "visible" >> $CTRL_FILE

    # Hide the window from taskbar, make it sticky and keep it above
    # all others.
    wmctrl -b add,skip_taskbar -i -r $WINDOW_ID
    wmctrl -b add,above -i -r $WINDOW_ID
    wmctrl -b add,sticky -i -r $WINDOW_ID

    exit 0
fi

# Retrieve the hex ID and the state of the managed window.
WINDOW_ID=$(head -n1 $CTRL_FILE)
WINDOW_STATE=$(tail -n1 $CTRL_FILE)

# Show/hide the window.
wmctrl -b toggle,hidden -i -r $WINDOW_ID

# Construct the contents of $CTRL_FILE anew.
echo $WINDOW_ID > $CTRL_FILE

if [ $WINDOW_STATE = "visible" ]
then
    WINDOW_STATE="hidden"
else
    WINDOW_STATE="visible"

    # Bring the terminal window to front.
    wmctrl -i -R $WINDOW_ID
fi
echo $WINDOW_STATE >> $CTRL_FILE
