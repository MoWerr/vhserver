#!/usr/bin/with-contenv bash
source /common.sh

msg "Stop signal received. Stopping the server..."
s6-setuidgid husky vhserver stop

if [[ $? != 0 ]]; then
    msg "Server stopped gracefully."
else
    err "Server couldn't be stopped gracefully!"
    exit 1
fi