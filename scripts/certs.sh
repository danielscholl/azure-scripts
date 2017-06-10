#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Create Docker CA Certificates on a remote host over ssh
#  Requires: certgen.rb
#  Usage:
#    certs.sh <hostname>

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace



if [[ ! $1 ]]; then
    echo "no hostname argument passed"
	exit 1
fi

HOST=$1

if [[ ! $IP ]]; then
	tput setaf 1; echo 'Retrieving the IP Address for' $HOST; tput sgr0
	IP=$(az vm list-ip-addresses -n $HOST | jq -r ".[] | .virtualMachine.network.publicIpAddresses[].ipAddress")
fi

echo 'Connecting to' $USER@$IP


tput setaf 1; echo 'Performing Package Update' $HOST; tput sgr0
ssh -i ~/.ssh/id_rsa $USER@$IP  "sudo apt-get update"

tput setaf 1; echo 'Installing Ruby' $HOST; tput sgr0
ssh -i ~/.ssh/id_rsa $USER@$IP  "sudo apt-get install -y ruby ruby-dev build-essential"

tput setaf 1; echo 'Installing Ruby Gem Certificate Authority' $HOST; tput sgr0
ssh -i ~/.ssh/id_rsa $USER@$IP  "sudo gem install certificate_authority"

scp -i ~/.ssh/id_rsa ./certgen.rb ${USER}@${IP}:/home/${USER}  # Copy CertGen File

tput setaf 1; echo 'Creating Certs' $HOST; tput sgr0
ssh -i ~/.ssh/id_rsa $USER@$IP  "ruby certgen.rb $USER.privateca.com"
mkdir -p certs/$HOST
scp -i ~/.ssh/id_rsa ${USER}@${IP}:/home/${USER}/.docker/*.pem ./certs/$HOST/
