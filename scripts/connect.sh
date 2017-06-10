#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Easily SSH to a Unique Azure VM (Hostname must be unique)
#  Usage:
#    connect.sh <hostname> <user>

if [[ ! $1 ]]; then
    echo "no hostname argument passed"
	exit 1
fi

if [[ $2 ]]; then
	USER=$2
fi

HOST=$1

#////////////////////////////////
echo 'Retrieving IP Address for' ${HOST}

IP=$(az vm list-ip-addresses -n ${HOST} --query [].virtualMachine.network.publicIpAddresses[].ipAddress -o tsv)

echo 'Connecting to' $USER@$IP

ssh -i ~/.ssh/id_rsa $USER@$IP -A
