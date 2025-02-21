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

#validator-bonds -um configure-bond $validatorVoteAccountPubKey --authority $keysPath/$validatorKeyFileStaked --bond-authority $keysPath/bond-marinade.json --cpmpe 0 --max-stake-wanted 0 -k $keysPath/$validatorKeyFileStaked
validator-bonds -um configure-bond $validatorVoteAccountPubKey --authority $keysPath/$validatorKeyFileStaked --bond-authority $keysPath/bond-marinade.json --cpmpe 0 --max-stake-wanted 50000000000000 -k $keysPath/$validatorKeyFileStaked
