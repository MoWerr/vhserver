#!/bin/bash
source /common.sh

s6-setuidgid husky vhserver monitor || exit 1