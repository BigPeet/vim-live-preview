#!/usr/bin/env bash

# Expecting everything to be setup correctly.
vim -Nu <(cat << VIMRC
source ~/.vimrc
set rtp+=.
set rtp+=./examples
set rtp+=./examples/clang
VIMRC) -c 'Vader! test/*' > /dev/null
