#!/usr/bin/env bash
shopt -u progcomp
export scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`

export colorRed=$'\e[1;31m'
export colorYellow=$'\e[1;33m'
export colorGreen=$'\e[1;32m'
export colorBlue=$'\e[1;34m'
export colorEnd=$'\e[0m'

export execSolana=`which solana`
export execSolanaValidator=`which agave-validator`
export execSolanaKeygen=`which solana-keygen`
export execSolanaWatchtower=`which solana-watchtower`
export execSolanaLedgerTool=`which agave-ledger-tool`

# In case of using primary and secondary nodes, my naming is e.g.: mainnet-1, testnet-2 and etc..
export systemHostname=`hostname -s`
export networkType="mainnet"
export systemSolanaService="solana-$networkType.service" #in my case of testnet: solana-testnet.service. Will add a rule.

export nodeID="1"
export rpcURL="http://localhost:8899"
configJsonRpcUrl=`${execSolana} config get json_rpc_url | awk '{print $3}'`
configWebsocketUrl=`${execSolana} config get websocket_url | awk '{print $3}'`

export logPath="$HOME/snode"
export nodePath="$HOME/snode"
export validatorPath="$nodePath/$networkType"
export ledgerPath="$validatorPath/ledger"
export snapshotsPath="$validatorPath/snapshots"
export accountsPath="$validatorPath/accounts"
export accounts_hash_cachePath="$validatorPath/accounts_hash_cache"
export accounts_indexPath="$validatorPath/accounts_index"
export keysPath="$nodePath/sol-keys/$networkType-$nodeID"
#ledgerClusterType=`${execSolanaLedgerTool} -l $ledgerPath genesis | grep -i cluster | awk '{print $3}'`

export validatorKeyFile="validator-keypair.json"
export validatorKeyFileStaked="validator-staked-keypair.json"
export validatorKeyFileUnstaked1="validator-unstaked-1-keypair.json"
export validatorKeyFileUnstaked2="validator-unstaked-2-keypair.json"
export validatorVoteAccountKeyFile="vote-account-keypair.json"
export validatorIdentityPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFile`
export validatorIdentityPubKeyStaked=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFileStaked`
export validatorVoteAccountPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorVoteAccountKeyFile`
export validatorSelfstakeAccountPubkey=`cat $keysPath/selfstake-account.addr`
export validatorBondMarinadePubkey=`cat $keysPath/bond-marinade.addr`

echo
echo -ne "Checking config ... "

#        if  [[ "$networkType" == "testnet" && "$ledgerClusterType" == "Testnet" ]]; then
	if  [[ "$networkType" == "testnet" ]]; then

		if [[ "$configJsonRpcUrl" == *"testnet"* && "$configWebsocketUrl" == *"testnet"* ]]; then
                        echo "[$colorGreen $networkType $colorEnd]"
		else
			export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
			$execSolana config set --url https://api.testnet.solana.com
			$execSolana config set --keypair $keysPath/$validatorKeyFile
		fi
	fi


#        if  [[ "$networkType" == "mainnet" && "$ledgerClusterType" == "MainnetBeta" ]]; then
	if  [[ "$networkType" == "mainnet" ]]; then

		export solanaPrice=$(curl -sf --insecure --connect-timeout 2 'https://api.margus.one/solana/price/' | jq -r .price | jq '.*1000|round/1000')

		if [[ "$configJsonRpcUrl" == *"mainnet"* && "$configWebsocketUrl" == *"mainnet"* ]]; then
			echo "[$colorGreen $networkType $colorEnd]"
		else
			export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
			$execSolana config set --url https://api.mainnet-beta.solana.com
			$execSolana config set --keypair $keysPath/$validatorKeyFile
		fi	
	fi
	

export epochInfo=`curl -s $rpcURL -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getEpochInfo"}'`
export slotAbsolute=`echo $epochInfo | jq .result.absoluteSlot`
export epochNumberCurrent=`echo $epochInfo | jq .result.epoch`
export slotIndex=`echo $epochInfo | jq .result.slotIndex`
