#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"

targetIPAddress="0.0.0.0"
targetSSHport=22

echo Trasnfering tower- file:
/usr/bin/rsync -a -e "ssh -p $targetSSHport" $ledgerPath/tower-1_9-$validatorIdentityPubKeyStaked.bin $USER@$targetIPAddress:$ledgerPath/

echo Setting new identity:
ln -sf $keysPath/$validatorKeyFileUnstaked1 $keysPath/$validatorKeyFile
$execSolanaValidator -l $ledgerPath set-identity $keysPath/$validatorKeyFileUnstaked1

echo
echo "Done!"
