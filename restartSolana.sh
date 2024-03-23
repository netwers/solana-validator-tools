#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo
date
echo "Please, do sudo =>"
sudo echo "Thanks!"
echo ""
echo "Restarting solana..."
echo ""
$execSolanaValidator --ledger $ledgerPath wait-for-restart-window --max-delinquent-stake 5  --min-idle-time 70 && sudo systemctl stop solana.service && sudo systemctl start solana.service
