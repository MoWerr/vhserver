#!/usr/bin/with-contenv bash
source /common.sh

msg "Stop signal received. Stopping the server..."
s6-setuidgid husky vhserver stop

if [[ $? != 0 ]]; then
    err "Server couldn't be stopped gracefully!"
    exit 1
else
    msg "Server stopped gracefully."
fi