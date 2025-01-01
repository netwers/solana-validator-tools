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
echo "Please, do sudo =>"
sudo echo "Thanks!"
echo ""
echo "Starting solana..."
echo ""

rpcIPAddress="185.81.65.80"
rpcURL="http://$rpcIPAddress"

wget -P $validatorPath/snapshots/ --content-disposition $rpcURL/snapshot.tar.bz2 && \
	wget -P $validatorPath/incremental_snapshots/ --content-disposition $rpcURL/incremental-snapshot.tar.bz2 && \
	sudo service $systemSolanaService start && \
	$execSolanaValidator --ledger $ledgerPath monitor

