#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo
echo "Solana Validator identity transition:"
date
echo "Probing servers..."
echo $solanaServers

n=`echo $solanaServers | jq length`



BUCKETS=()
while IFS= read -r entry; do
    BUCKETS+=("$entry")
done < <(jq '. | .[].ipAddress' $solanaServers)

echo Setting new identity:
#cd /home/af/snode/sol-keys/mainnet-1
#ln -sf validator-unstaked-2-keypair.json validator-keypair.json
#solana-validator -l /home/af/snode/mainnet/ledger set-identity /home/af/snode/sol-keys/mainnet-1/validator-unstaked-2-keypair.json
echo
echo Moving tower- file to backup dir:
#mv /home/af/snode/mainnet/ledger/tower-1_9-3kiyzZdvgkxhkef8v8cgbWe7JJ6a7NyNDpXMPnEUpb7x.bin /home/af/snode/bin/
echo Trasnfering tower- file:
#/usr/bin/rsync -a -e "ssh -p 50173" /home/af/snode/bin/tower-1_9-3kiyzZdvgkxhkef8v8cgbWe7JJ6a7NyNDpXMPnEUpb7x.bin af@104.238.220.248:/home/af/snode/mainnet/ledger/
echo
echo Checking:
#solana validators --output=json | jq '.validators[] | select(.identityPubkey=="3kiyzZdvgkxhkef8v8cgbWe7JJ6a7NyNDpXMPnEUpb7x")'

