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

export keysPath="$HOME/snode/sol-keys/$networkType-$nodeID"
export validatorKeyFile="validator-keypair.json"
export validatorKeyFileStaked="validator-staked-keypair.json"
export validatorVoteAccountKeyFile="vote-account-keypair.json"
export validatorIdentityPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFile`
export validatorIdentityPubKeyStaked=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFileStaked`
export validatorVoteAccountPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorVoteAccountKeyFile`
export validatorSelfstakeAccountPubkey=`cat $keysPath/selfstake-account.addr`

	if  [[ "$networkType" == "testnet" ]]; then
		export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
		$execSolana config set --url https://api.testnet.solana.com
		$execSolana config set --keypair $keysPath/$validatorKeyFile
	fi

	if  [[ "$networkType" == "mainnet" ]]; then
		export solanaPrice=$(curl -sf --insecure --connect-timeout 2 'https://api.margus.one/solana/price/' | jq -r .price | jq '.*1000|round/1000')
		export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
		$execSolana config set --url https://api.mainnet-beta.solana.com
		$execSolana config set --keypair $keysPath/$validatorKeyFile
	fi
	

export epochInfo=`curl -s $rpcURL -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getEpochInfo"}'`
export slotAbsolute=`echo $epochInfo | jq .result.absoluteSlot`
export epochNumberCurrent=`echo $epochInfo | jq .result.epoch`
export slotIndex=`echo $epochInfo | jq .result.slotIndex`
