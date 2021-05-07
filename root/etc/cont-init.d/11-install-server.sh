#!/usr/bin/with-contenv bash
source /common.sh

## Install server
if [[ ! -d $SERVERDIR/serverfiles ]]; then
    msg "Server files not found, installing the server..."
    s6-setuidgid husky vhserver auto-install
    
    if [[ $? != 0 ]]; then
        err "Server couldn't be installed properly."
        exit 1
    fi

    msg "Server installed."
    msg "Set your configuration and start the container again."
    exit 1
fi