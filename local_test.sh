#!/usr/bin/env bash

SCRIPT_NAME=$0
SCRIPT_DIR=$(dirname $SCRIPT_NAME)
PLUGIN_DIR=$SCRIPT_DIR

# Expecting everything to be setup correctly.
vim -Nu <(cat << VIMRC
source $HOME/.vimrc
set rtp+=$PLUGIN_DIR
VIMRC) -c "Vader! ${PLUGIN_DIR}/test/test_*.vader" > /dev/null
