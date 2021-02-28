#!/bin/bash

## Surpasses non-critical errors that are related to the 'unnamed' user
function command {
    $* 2> >(grep -v "cannot find name for user ID $UID\|The argument to -user should not be empty" >&2)
}

## Calls specific linuxgsm command
function server_command {
    command $SERVERDIR/vhserver $* 
}

## Checks if given directory exists
## If not, it will create one
function check_dir {
    if [[ ! -d "$1" ]]; then
        echo " ---> $1 directory not found, creating one..."
        mkdir -p "$1"
    fi
}

## Function that will stop the server
## And kill the child process
function stop_server {
    echo " ---> Stop signal received. Stopping the server..."
    server_command stop
    echo " ---> Server stopped gracefully."

    if [[ -v $child ]]; then
        kill -TERM $child 2> /dev/null
    fi
}

## Register stop signal function
trap stop_server SIGINT SIGTERM

## Check for missing directories.
## It can happen when user will mount his own volumes.
check_dir $STEAMCMDDIR
check_dir $LOCALDIR
check_dir $CONFIGDIR
check_dir $TEMPDIR

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
    command ./linuxgsm.sh vhserver
fi

## Install server
if [[ ! -d ./serverfiles ]]; then
    echo " ---> Server files not found, installing the server..."
    server_command auto-install
    echo " ---> Server installed. Make sure that everything end up with success before continuation."
    echo " ---> Set your configuration and start the container again."
    exit 0
fi

## Update the server
echo " ---> Updating the server..."
server_command update 

## Start the server
echo " ---> Starting the server..."
server_command start 

## Make sure the container won't be stopped
## Run in the background for proper SIGTERM signal processing
tail -f /dev/null &

## Read 'tail' PID
child=&!

## Wait till child process will end
wait $child