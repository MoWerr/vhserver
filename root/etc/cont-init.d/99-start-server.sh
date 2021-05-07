#!/usr/bin/with-contenv bash
source /common.sh

## Start the server
msg "Starting the server..."
s6-setuidgid husky vhserver start 

if [[ $? != 0 ]]; then
    err "Couldn't start the server."
    exit 1
fi