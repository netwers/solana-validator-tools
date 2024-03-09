#!/bin/bash
echo ""
date
echo "Please, do sudo =>"
sudo echo "Thanks!"
echo ""
echo "Restarting solana..."
echo ""
solana-validator --ledger ~/snode/ledger/ wait-for-restart-window --max-delinquent-stake 5  --min-idle-time 70 && sudo systemctl stop solana.service && sudo systemctl start solana.service
