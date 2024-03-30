#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo

airdropSignature=`$execSolana airdrop 1 $keysPath/$validatorKeyFile | grep -i "signature:" | awk '{print $2}'`
echo
echo Result: $airdropSignature
echo

        if [[ ! -z $airdropSignature ]]; then
                $execSolana confirm -v $airdropSignature
        else echo "Airdrop failed"
        fi

