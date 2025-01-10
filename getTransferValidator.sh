#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"

ln -sf $keysPath/$validatorKeyFileStaked $keysPath/$validatorKeyFile
$execSolanaValidator -l $ledgerPath set-identity --require-tower $keysPath/$validatorKeyFileStaked

echo
echo "Done!"
