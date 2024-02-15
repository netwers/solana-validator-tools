#!/usr/bin/env bash

export scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`

export colorRed=$'\e[1;31m'
export colorGreen=$'\e[1;32m'
export colorBlue=$'\e[1;34m'
export colorEnd=$'\e[0m'

export execSolana=`which solana`
export execSolanaValidator=`which solana-validator`
export execSolanaKeygen=`which solana-keygen`
export execSolanaWatchtower=`which solana-watchtower`
export logPath="$HOME/snode/"

# In case of using primary and secondary nodes, my naming is e.g.: mainnet-1, testnet-2 and etc..
export networkType="mainnet"
export nodeID="1"
export rpcURL="http://localhost:8899"
export solanaPrice=$(curl -sf --connect-timeout 2 'https://api.margus.one/solana/price/' | jq -r .price | jq '.*1000|round/1000')

export keysPath="$HOME/snode/sol-keys/$networkType-$nodeID"
export validatorKeyFile="validator-keypair.json"
export validatorKeyFileStaked="validator-staked-keypair.json"
export validatorVoteAccountKeyFile="vote-account-keypair.json"
export validatorIdentityPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFile`
export validatorIdentityPubKeyStaked=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFileStaked`
export validatorVoteAccountPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorVoteAccountKeyFile`

export epochInfo=`curl -s $rpcURL -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getEpochInfo"}'`
export slotAbsolute=`echo $epochInfo | jq .result.absoluteSlot`
export epochNumberCurrent=`echo $epochInfo | jq .result.epoch`
export slotIndex=`echo $epochInfo | jq .result.slotIndex`
