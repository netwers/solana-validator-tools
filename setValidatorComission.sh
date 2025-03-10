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
$execSolana vote-update-commission $keysPath/$validatorVoteAccountKeyFile 0 withdraw-authority.json --keypair $keysPath/$validatorKeyFileStaked
