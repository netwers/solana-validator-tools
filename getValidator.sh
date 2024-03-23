#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo
date
echo

        if [[ -z $1 ]]; then
		echo "Validator pubkey (identity) unspecified. I gonna use $validatorIdentityPubKey from env.sh instead."
                echo "Usage: $0 <vote-account-addr>"
        else
                validatorIdentityPubKey=$1
        fi

$execSolana validators --output=json | jq ".validators[] | select(.identityPubkey==\"$validatorIdentityPubKey\")"
