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

validatorIdentityPubKey="3kiyzZdvgkxhkef8v8cgbWe7JJ6a7NyNDpXMPnEUpb7x"

$execSolana validators --output=json | jq ".validators[] | select(.identityPubkey==\"$validatorIdentityPubKey\")"
