#!/bin/bash
# Copyright (c) 2017, cloudcodeit.com

## This Script will do an upgrade of packages over Azure Custom Script Extensions
#   NOTE: walinuxagent upgrades will hang the Custom Script from running and needs to be ignored

function doUpgrade() {
    apt-get -y update
    apt-get -y dist-upgrade
    apt-get -y update
    echo "System Update Completed -- $(date -R)!"
}

apt-mark hold walinuxagent
doUpgrade | tee /var/log/custom-script.log
# apt-mark unhold walinuxagent
