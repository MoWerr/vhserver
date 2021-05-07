#!/bin/bash
source /common.sh

s6-setuidgid husky vhserver monitor

if [[ $? != 0 ]]; then
  echo "[$(date "+%d/%m/%y %H:%M:%S")] Server was down during last healthcheck!" >> /data/cronjobs.log
  exit 1
else
  exit 0
fi