#!/bin/bash

## Function that will stop the server
## And kill the child process
function stop_server {
    echo " ---> Stop signal received. Stopping the server..."
    $SERVERDIR/vhserver stop
    echo " ---> Server stopped gracefully."

    if [[ -v $child ]]; then
        kill -TERM $child 2> /dev/null
    fi
}

## Register stop signal function
trap stop_server SIGINT SIGTERM

## Check for missing directories.
## It can happen when user will mount his own volumes.
if [[ ! -d $STEAMCMDDIR ]]; then
    echo " ---> SteamCMD directory not found, creating one..."
    mkdir -p $STEAMCMDDIR
fi
if [[ ! -d $LOCALDIR ]]; then
    echo " ---> .local directory not found, creating one..."
    mkdir -p $LOCALDIR
fi
if [[ ! -d $CONFIGDIR ]]; then
    echo " ---> .config directory not found, creating one..."
    mkdir -p $CONFIGDIR
fi

## Update the umask if necessary.
if [[ -z $UMASK ]]; then
    ## Updating UMASK is important, so we inform explicitly that it won't be changed.
    echo " ---> UMASK variable is not set, skipping update"
else
    echo " ---> Setting UMASK to provided value"
    umask $UMASK && read_value=$(umask) && echo " ---> UMASK = ${read_value}"
fi

## Download the steamcmd
if [[ ! -f $STEAMCMDDIR/steamcmd.sh ]]; then
    echo " ---> steamcmd.sh not found, installing SteamCMD..."
    wget -qO- "https://steamcdn-a.akamaihd.net/client/installer/steamcmd"_linux.tar.gz | tar xvzf - -C "${STEAMCMDDIR}" 
    $STEAMCMDDIR/steamcmd.sh +quit
fi

## At this point we will operate only within the server directory
cd $SERVERDIR

## Download the linuxGSM
if [[ ! -f ./linuxgsm.sh ]]; then
    echo " ---> linuxgsm.sh not found, downloading main script..."
    wget -qO ./linuxgsm.sh "https://linuxgsm.sh" && chmod +x ./linuxgsm.sh
fi

## Create server instance
if [[ ! -f ./vhserver ]]; then
    echo " ---> Server instance not found, creating one..."
    ./linuxgsm.sh vhserver
fi

## Install server
if [[ ! -d ./serverfiles ]]; then
    echo " ---> Server files not found, installing the server..."
    ./vhserver auto-install
fi

## Update the server
echo " ---> Updating the server..."
./vhserver update

## Start the server
echo " ---> Starting the server..."
./vhserver start

## Make sure the container won't be stopped
## Run in the background for proper SIGTERM signal processing
tail -f /dev/null &

## Read 'tail' PID
child=&!

## Wait till child process will end
wait $child