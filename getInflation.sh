#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo


	if [[ -z $1 ]] || [[ -z $2 ]]; then
		epochNumber=$(($epochNumberCurrent - 1))
		echo "Parameters missed. I gonna use $validatorVoteAccountPubKey from env.sh instead and current epoch-1 ($epochNumberCurrent - 1 = $epochNumber)."
                echo "Usage: $0 <vote-account-addr-or-keypair> <epoch>"
                echo "Make sure epoch specified is completed."
        else
                validatorVoteAccountPubKey=$1
                epochNumber=$2
        fi

date
echo

solana inflation rewards $validatorVoteAccountPubKey --rewards-epoch $epochNumber

