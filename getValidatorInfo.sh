#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"


        if [[ -z $1 ]]; then
		echo "Validator pubkey (identity) unspecified. I gonna use $validatorIdentityPubKey from env.sh instead."
                echo "Usage: $0 <validator_identity_pubkey>"
        else
                validatorIdentityPubKey=$1
        fi

rpcURL="https://mainnet.helius-rpc.com/?api-key=2c98b537-1ed6-4def-9dbb-d1cdfa12dba6"
$execSolana validators --url $rpcURL --output=json | jq ".validators[] | select(.identityPubkey==\"$validatorIdentityPubKey\")"
