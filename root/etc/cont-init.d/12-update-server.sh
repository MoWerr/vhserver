#!/usr/bin/with-contenv bash
source /common.sh

## Update the server
msg "Updating the server..."
s6-setuidgid husky vhserver update 

if [[ $? != 0 ]]; then
    err "Couldn't update the server."
    exit 1
fi