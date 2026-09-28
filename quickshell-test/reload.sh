#!/bin/bash

if pgrep -x "qs" > /dev/null
then
    # If it is running, kill it
    pkill qs
else
    # If it's not running, start it
    qs &
fi