#!/bin/bash
################################################################################
# Set up TMUX
echo set -g default-terminal "xterm-256color" > .tmux.conf
env SHELL=/usr/bin/bash tmux new -s install

# Use this to re-attch to a session:
# tmux attach-session -t install
