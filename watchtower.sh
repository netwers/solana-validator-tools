#!/usr/bin/env bash

#
# Solana Validator tool script by Netwers, 2022-2024.
#
# Do not forget to declare environment params for notifications first in $HOME/.profile:
#  export TELEGRAM_BOT_TOKEN="0000000000:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
#  export TELEGRAM_CHAT_ID="123456789"
#  export TWILIO_CONFIG='ACCOUNT=<ACCOUNT_SID>,TOKEN=<ACCOUNT_KEY>,TO=<YOUR_PHONE_NUMBER>,FROM=<SENDER_PHONE_NUMBER>'
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"


        if [[ -z $1 ]]; then
                echo "Validator identity unspecified. I gonna use $validatorIdentityPubKeyStaked from env.sh instead."
                echo "Usage: $0 <validator-identity-pubkey>"
                validatorIdentityPubKey=$validatorIdentityPubKeyStaked
        else
                validatorIdentityPubKey=$1
        fi

echo ""
date
echo ""

$execSolanaWatchtower --monitor-active-stake --validator-identity $validatorIdentityPubKey --minimum-validator-identity-balance 1 --interval 30
