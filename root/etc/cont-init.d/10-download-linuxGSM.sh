#!/usr/bin/with-contenv bash
source /common.sh

## Chekf if main directory for vhserver exists
check_dir $SERVERDIR
chown husky:husky $SERVERDIR

cd $SERVERDIR

## Download the linuxGSM
if [[ ! -f ./linuxgsm.sh ]]; then
    msg "linuxgsm.sh not found, downloading main script..."
    wget -qO ./linuxgsm.sh "https://linuxgsm.sh" &&
     chmod +x ./linuxgsm.sh &&
     chown husky:husky ./linuxgsm.sh
fi

## Create server instance
if [[ ! -f ./vhserver ]]; then
    msg "Server instance not found, creating one..."
    s6-setuidgid husky ./linuxgsm.sh vhserver

    if [[ $? != 0 ]]; then
        err "Couldn't create the server instance."
        exit 1
    fi
fi