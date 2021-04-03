#!/bin/bash
source /common.sh

# Shortcut for server command.
function vhserver {
    $SERVERDIR/vhserver $@
}

## Function that will stop the server
## And kill the child process
function stop_server {
    msg "Stop signal received. Stopping the server..."
    vhserver stop

    if [[ $? != 0 ]]; then
        msg "Server stopped gracefully."
    else
        err "Server couldn't be stopped gracefully!"
    fi

    if [[ -v $child ]]; then
        kill -TERM $child 2> /dev/null
    fi
}

## Register stop signal function
trap stop_server SIGINT SIGTERM

## Chekf if main directory for vhserver exists
check_dir $SERVERDIR

## At this point we will operate only within the server directory
cd $SERVERDIR

## Download the linuxGSM
if [[ ! -f ./linuxgsm.sh ]]; then
    msg "linuxgsm.sh not found, downloading main script..."
    wget -qO ./linuxgsm.sh "https://linuxgsm.sh" && chmod +x ./linuxgsm.sh
fi

## Create server instance
if [[ ! -f ./vhserver ]]; then
    msg "Server instance not found, creating one..."
    ./linuxgsm.sh vhserver

    if [[ $? != 0 ]]; then
        err "Couldn't create the server instance."
        exit 1
    fi
fi

## Install server
if [[ ! -d ./serverfiles ]]; then
    msg "Server files not found, installing the server..."
    vhserver auto-install
    
    if [[ $? != 0 ]]; then
        err "Server couldn't be installed properly."
        exit 1
    fi

    msg "Server installed."
    msg "Set your configuration and start the container again."
    exit 0
fi

## Update the server
msg "Updating the server..."
vhserver update 

if [[ $? != 0 ]]; then
    err "Couldn't update the server."
    exit 1
fi

## Start the server
msg "Starting the server..."
vhserver start 

if [[ $? != 0 ]]; then
    err "Couldn't start the server."
    exit 1
fi

## Make sure the container won't be stopped
## Run in the background for proper SIGTERM signal processing
tail -f /dev/null &

## Read 'tail' PID
child=&!

## Wait till child process will end
wait $child