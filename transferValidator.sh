#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"

targetUsername="sshUser"
targetIPAddress="0.0.0.0"
targetSSHport="22"
targetLedgerPath=$ledgerPath # Your remote machine's ledger path, e.g.: /home/user/solana/ledger/

echo Trasnfering tower- file:
/usr/bin/rsync -a -e "ssh -p $targetSSHport" $ledgerPath/tower-1_9-$validatorIdentityPubKeyStaked.bin $targetUsername@$targetIPAddress:$targetLedgerPath/

echo Setting new identity:
ln -sf $keysPath/$validatorKeyFileUnstaked1 $keysPath/$validatorKeyFile
$execSolanaValidator -l $ledgerPath set-identity $keysPath/$validatorKeyFileUnstaked1

echo
echo "Done!"
