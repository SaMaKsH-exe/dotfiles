1



#!/bin/sh

# Check if a Tmux session named 'main' already exists
tmux has-session -t main 2>/dev/null

if [ $? != 0 ]; then
    # If no session exists, create a new one and attach to it
    tmux new-session -s main
else
    # If a session exists, attach to it
    tmux attach-session -t main
fi
