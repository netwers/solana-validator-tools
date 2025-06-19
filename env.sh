#!/usr/bin/env bash

function die ()
{
    if [ -n "$1" ]
    then
        echo "$1"
    fi

#    exit -1
}

function required ()
{
    which $1 1>/dev/null 2>/dev/null || die "ERROR: $1 required, but not found."
}

required solana
required solana-keygen
required agave-validator
required base64
required jq
required yq
required bc
required curl
required rsync
required ssh
required nmap
required nc

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`

colorRed=$'\e[1;31m'
colorYellow=$'\e[1;33m'
colorGreen=$'\e[1;32m'
colorBlue=$'\e[1;34m'
colorEnd=$'\e[0m'

export execSolana=`which solana`
export execSolanaValidator=`which agave-validator`
export execSolanaKeygen=`which solana-keygen`
export execSolanaWatchtower=`which solana-watchtower`
export execSolanaLedgerTool=`which agave-ledger-tool`
export execNmap=`which nmap`
# In case of using primary and secondary nodes, my naming is e.g.: mainnet-1, testnet-2 and etc..
export systemHostname=`hostname -s`
export systemIPAddress=$(curl -sf --insecure --connect-timeout 2 'https://netwers.com/')
export systemSSHPort=$(cat /etc/ssh/sshd_config | grep -iw port | awk '{print $2}')
export serversListFileName="serversList.json"
export serversListFilePath="$nodePath/$serversListFileName"
                                 #            🔻🔻🔻
        # ============================================================================= #
	# serversList.json structure example:						#
	#										#
	#  [										#
	#    {										#
	#     "serverName": "solana-mainnet-1",						#
	#     "ipAddress": "38.24.18.15",						#
	#     "sshPort": "22",								#
	#     "serverUserName": "user",							#
	#     "destinationServer": "true",						#
	#     "sshPortStatus": null,							#
	#     "sshCertPath": "/home/user/ssh-certs/solana-mainnet-1/id_rsa",		#
	#     "online": null,								#
	#     "ping": null,								#
	#     "sshConnection": null,							#
	#     "systemUsageRAM": null,							#
	#     "systemUsageCPU": null,							#
	#     "systemUsageStorageLedger": null,						#
	#     "systemUsageStorageAccounts": null,					#
	#     "validator": null,							#
	#     "delinquent": null,							#
	#     "catchup": null,								#
	#     "localServer": "false",							#
	#     "updatedUnixtime": null							#
	#    }										#
	#  ]										#
        #                                                                               #
        # ============================================================================= #

export sshCertsPath="$nodePath/ssh-certs"
export sshCertFileName="id_rsa"
export networkType="mainnet"
export systemSolanaService="solana-$networkType.service" #in my case of testnet: solana-testnet.service. Will add a rule.

export nodeID="1"
export rpcURL="http://localhost:8899"
export rpcURL1="https://api.mainnet-beta.solana.com"
export rpcURL2="https://a1pi.mainnet-beta.solana.com"
export rpcURL3="https://apii.mainnet-beta.solana.com"
rpcServers=("$rpcURL1" "$rpcURL2" "$rpcURL3")

configJsonRpcUrl=`${execSolana} config get json_rpc_url | awk '{print $3}'`
configWebsocketUrl=`${execSolana} config get websocket_url | awk '{print $3}'`

export nodePath="$HOME/snode"
export validatorPath="$nodePath/$networkType"
export ledgerPath="$validatorPath/ledger"
export snapshotsPath="$validatorPath/snapshots"
export snapshotsIncrementalPath="$validatorPath/incremental_snapshots"
export accountsPath="$validatorPath/accounts"
export accounts_hash_cachePath="$validatorPath/accounts_hash_cache"
export accounts_indexPath="$validatorPath/accounts_index"
export keysPath="$nodePath/sol-keys/$networkType-$nodeID"
export notificationConfigPath="$nodePath/notificationConfig.json"
                                 #            🔻🔻🔻
	# ============================================================================= #
	# notificationConfig.json structure example:					#
	#										#
	#   {										#
	#   "telegramBotToken": "0123456789:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",	#
	#   "telegramChatID":   "0000000000"						#
	#   "voipCallURI":      "https://voip_pbx_api_url/"                             #
	#   }										#
	#                                                                               #
	# ============================================================================= #

logPath=$nodePath
logFile="journal.log"

export validatorKeyFile="validator-keypair.json"
export validatorKeyFileStaked="validator-staked-keypair.json"
export validatorKeyFileUnstaked1="validator-unstaked-1-keypair.json"
export validatorKeyFileUnstaked2="validator-unstaked-2-keypair.json"
export validatorKeyFileUnstaked3="validator-unstaked-3-keypair.json" # We have 3 mainnet servers (1x primary, 2x secondary)
export validatorKeyFileUnstaked=$validatorKeyFileUnstaked2 # default unstaked keypair for local (current) machine
export validatorVoteAccountKeyFile="vote-account-keypair.json"
export validatorVoteAccountAddrFile="vote-account-keypair.addr"
export validatorIdentityPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFile`
export validatorIdentityPubKeyStaked=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFileStaked`
export validatorVoteAccountPubKey=`cat $keysPath/$validatorVoteAccountAddrFile`
export validatorSelfstakeAccountPubkey=`cat $keysPath/selfstake-account.addr`


# functions

function checkConnectionInternet()
{
	local result=false
	local hosts=("1.1.1.1" "79.174.71.189" "www.noc.org")

	for host in "${hosts[@]}"
	do
		ping -c1 $host &> /dev/null

			if [[ $? -eq 0 ]]
			then
				result=true
				echo $result
				return
			fi
	done

	echo $result
	return
}


function checkConnectionHost()
{
	local result=false
	local host=$1
	#echo -n "Checking connection to $host... "

	ping -c2 $host &>/dev/null
		if [[ $? -eq 0 ]]
		then
			result=true
		else
			result=false
		fi

	echo $result
	return
}


function getCatchup()
{
	local result=false
	local diff=false
	local getSlotThem=0
	local getSlotUs=0

	for rpcServer in "${rpcServers[@]}"
	do
		echo -n "Requesting cluster slot ... " >&2
		getSlotThem=`$execSolana slot --url $rpcServer --commitment confirmed 2>/dev/null`

			if [[ "$getSlotThem" -gt 0 ]]
			then
				result=true
				echo "[$colorGreen $getSlotThem $colorEnd]" >&2
				break
			else
				result=false
				echo "[$colorRed FAILED: $rpcServer $colorEnd]" >&2
				sendNotification "ERROR" "Failed to get cluster slot from external RPC $rpcServer, trying next one..."
			fi
	done


		if [[ "$result" == "true" ]]
		then
			echo -n "Requesting local slot   ... " >&2
			getSlotUs=`$execSolana slot --url $rpcURL --commitment confirmed 2>/dev/null`

				if [[ $? -eq 0 ]]
				then
			
					if [[ $getSlotUs -gt 0 ]]
					then
						result=true
						echo "[$colorGreen $getSlotUs $colorEnd]" >&2
						echo -n "Calculating catchup gap ... " >&2
						diff=$(($getSlotThem - $getSlotUs))
						echo "[$colorGreen $diff $colorEnd]" >&2
					else
						result=false
						echo "[$colorRed FAILED $colorEnd]" >&2
						#echo "Wrong value! Is node down?"
						sendNotification "ERROR" "Wrong value got from LOCAL RPC. Is node down?"
					fi
				else
					result=false
	        	                echo "[$colorRed FAILED $colorEnd]" >&2
               				echo "Failed to get slot number from local RPC. Is node down?" >&2
		                        sendNotification "ERROR" "Failed to get slot number from local RPC. Is node down?"
				fi
		else
			result=false
			echo "[$colorRed FAILED $colorEnd]" >&2
			echo "Failed to get cluster slot. Check URLs, RPC servers, connection and/or try again." >&2
			sendNotification "ERROR" "Failed to get cluster slot. Check URLs, RPC servers, connection and/or try again."
		fi

	echo $diff
}


function sendToLog()
{
	local result=""

	echo -n "Checking log path ... "

		if [ -d "$logPath" ]
		then
			echo "[$colorGreen OK $colorEnd]"
		else
			echo "[$colorRed FAILED $colorEnd]"
			echo -n "First run? Creating log path ... "
			mkdir -p $logPath
			result=$?
			
				if [ $result -eq 0 ]
				then
					echo "[$colorGreen OK $colorEnd]"
				else
					echo "[$colorRed FAILED $colorEnd]"
					echo "Check path, permissions, disk space and try again. Code: $result"
					sendToTelegram "$BASH_SOURCE:$FUNCNAME" "ERROR ($result): Couldn't create log path."
					exit $result
				fi
		fi

	echo -n "Checking log file ... "

		if [ -f $logPath/$logFile ]
		then
			echo "[$colorGreen OK $colorEnd]"
		else
			echo "[$colorRed FAILED $colorEnd]"
	                echo -n "First run? Creating log path ... "
	                touch $logPath/$logFile
			result=$?

	                        if [ $result -eq 0 ]
				then
        	                        echo "[$colorGreen OK $colorEnd]"
                	        else
                        	        echo "[$colorRed FAILED $colorEnd]"
	                                echo "Check file, permissions, disk space and try again. Code: $result"
	                                sendToTelegram "$BASH_SOURCE:$FUNCNAME" "ERROR ($result): Couldn't create log file."
	                                exit $result
	                        fi
		fi

	
		if [[ ! -z $1 ]]
		then
			eventType=$1
		else
			eventType="unknown_event"
		fi


		if [[ ! -z $2 ]]
		then
			eventBody=$2
		else
			eventBody="none"
		fi



	dateTimeNow=`date +"%Y-%m-%d %H:%M:%S"`
	echo "$dateTimeNow $systemHostname $1 $2" >> $logPath/$logFile
}


function sendToTelegram()
{
	telegramBotToken=$(cat $notificationConfigPath | jq '.telegramBotToken' | tr -d '"')
	telegramChatID=$(cat   $notificationConfigPath | jq '.telegramChatID'   | tr -d '"')


                if [[ ! -z $1 ]]
		then
                        messageTitle="$systemHostname: $1"
                else
                        messageTitle="$systemHostname: "
                fi


                if [[ ! -z $2 ]]
		then
                        messageBody=$2
                else
                        messageBody="test"
                fi


	if [[ ! -z ${messageBody} ]]
	then
		messageJSON=$(echo "" | awk -v TITLE="$messageTitle" -v MESSAGE="*${messageTitle}* ${messageBody}" -v CHAT_ID="$telegramChatID" '{
		print "{";
	        print "     \"chat_id\" : " CHAT_ID ","
        	print "     \"text\" : \"" MESSAGE "\","
	        print "     \"parse_mode\" : \"markdown\","
	        print "}";
	    }')

	   curl -s -d "$messageJSON" -H "Content-Type: application/json" -X POST https://api.telegram.org/bot${telegramBotToken}/sendMessage 2>/dev/null
   	else
	   curl -s --data parse_mode=HTML --data chat_id=${telegramChatID} --data text="<b>${messageTitle}</b>%0A${messageBody}" --request POST https://api.telegram.org/bot${telegramBotToken}/sendMessage 2>/dev/null
	fi
}


function sendAlert()
{
	local result=""

		if [[ ! -z $1 ]]
		then
                        notificationBody=$1
                else
                        notificationBody="unknown"
                fi


	voipCallURI=$(cat $notificationConfigPath | jq '.voipCallURI' | tr -d '"')


		if [[ -z $voipCallURI ]]
		then
			echo "Getting API URI for voip alerting ... [$colorRed FAILED $colorEnd]"
			echo "Check 'voipCallURI' value in the notification config $notificationConfigPath"
			sendNotification "ERROR" "Failed getting API URI for voip alerting. Check 'voipCallURI' value in the notification config $notificationConfigPath"
			exit $?
		else
			sendNotification "ALERT" "$notificationBody"
			result=`curl -s -v -d "solanaValidatorAlert" $voipCallURI 2>/dev/null`

				if [[ $? -eq 0 ]]
				then
					sendNotification "INFO" "Call alerting successfuly initiated"
				else
					echo "There is a problem with voip alerting function. Curl request failed"
					sendNotification "ERROR" "There is a problem with voip alerting function. Curl request failed"
				fi
		fi
}


function sendNotification()
{
		if [[ ! -z $1 ]]
		then
			notificationType=$1
                else
                        notificationType="INFO"
                fi

		if [[ ! -z $2 ]]
		then
			notificationBody=$2
		else
			notificationBody="unknown"
		fi

	sendToTelegram "$notificationType" "$notificationBody"
	sendToLog "$notificationType" "$notificationBody"
}


function getValidatorInfo()
{
        local result=false

	        for rpcServer in "${rpcServers[@]}"
	        do
			if [[ -z $1 ]]
			then
				echo "Validator pubkey (identity) unspecified. I gonna use $validatorIdentityPubKey from env.sh instead."
		               	echo "Usage: $FUNCNAME <validator_identity_pubkey>"
			else
				validatorIdentityPubKey=$1
			fi
			
		echo -n "Requesting validator info from cluster ... " >&2
				
		result=`$execSolana validators --url $rpcServer --output=json | jq ".validators[] | select(.identityPubkey==\"$validatorIdentityPubKey\")" 2>/dev/null`
			
			if [[ $? -eq 0 ]]
			then
				echo "[$colorGreen OK $colorEnd]" >&2
				echo $result
				break
			fi

		done

}


function getAirdrop()
{
	airdropSignature=`$execSolana airdrop 1 $keysPath/$validatorKeyFile | grep -i "signature:" | awk '{print $2}'`
	echo
	echo Result: $airdropSignature
	echo
	
	        if [[ ! -z $airdropSignature ]]
		then
			$execSolana confirm -v $airdropSignature -k $keysPath/$validatorKeyFile

		else
			echo "Airdrop failed"
	        fi
}


function getInflationRewards()
{
	echo

	        if [[ -z $1 ]] || [[ -z $2 ]]
		then
			epochNumber=$(($epochNumberCurrent - 1))

			echo "Parameters missed. I gonna use $validatorVoteAccountPubKey from env.sh and current epoch-1 instead ($epochNumberCurrent - 1 = $epochNumber)."
	                echo "Usage: $FUNCNAME <vote_account_pubkey-or-vote_account_keypair> <epoch>"
	                echo "Make sure specified epoch is complete."

		else
	                validatorVoteAccountPubKey=$1
	                epochNumber=$2
	        fi

	$execSolana inflation rewards $validatorVoteAccountPubKey --rewards-epoch $epochNumber
	echo
}


function getIPAddressByVoteAccount()
{

	        if [[ -z $1 ]]
		then
	                echo "Vote account unspecified. I gonna use $validatorVoteAccountPubKey from env.sh instead."
	                echo "Usage: $FUNCNAME <vote_account_addr>"
	        else
	                validatorVoteAccountPubKey=$1
	        fi

	validatorsJSON=`${execSolana} validators --output=json`
	gossipJSON=`${execSolana} gossip --output=json`
	validatorIdentityPubKey=`echo $validatorsJSON | jq '.validators[] | select (.voteAccountPubkey=="'$validatorVoteAccountPubKey'").identityPubkey' | tr -d "\""`
	ipAddress=`echo $gossipJSON | jq '.[] | select (.identityPubkey=="'$validatorIdentityPubKey'").ipAddress' | tr -d "\""`

	#echo $ipAddress >> $logPath/ipAddress-$validatorVoteAccountPubKey.txt
	#whois $ipAddress

	echo "Vote:     $validatorVoteAccountPubKey"
	echo "Identity: $validatorIdentityPubKey"
	echo "IP:       $ipAddress"
	echo
}


function getFoundationStatus()
{

	        if [[ -z $1 ]]; then
	                echo "Validator pubkey (identity) unspecified. I gonna use $validatorIdentityPubKey from env.sh instead."
	                echo "Usage: $FUNCNAME <validator_identity_pubkey>"
	        else
	                validatorIdentityPubKey=$1
	        fi

	getValidatorInfoFromSFDP=`curl https://api.solana.org/api/validators/$validatorIdentityPubKey`
	echo $getValidatorInfoFromSFDP | jq
}


function getBalances()
{

	addrFiles=$(find $keysPath/addrs -maxdepth 2 -type f -name "*.addr" | sort -n)
	echo $addrFiles | tr " " "\n" > addrFiles.tmp

	        while addrs= read -r addr
	        do
	                addrName=${addr#$keysPath/addrs/}
	                echo -n " $addrName: "
	
	                addrBalance=`$execSolana balance $(cat ${addr}) --output json | jq .lamports | jq './1000000|round/1000'`
	
	                        if ! [[ "$?" -eq 0 ]]
	                        then
	                                echo "0"
	                        else
	                                echo $addrBalance
	                        fi
	
	        done < addrFiles.tmp
	
	echo
	rm -rf addrFiles.tmp
}


function getDetailedEpochInfoByValidator()
{
                if [[ -z $1 ]] || [[ -z $2 ]]
                then
			epochInfo=`curl -s $rpcURL -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getEpochInfo"}'`
			epochNumberCurrent=`echo $epochInfo | jq .result.epoch`
                        epochNumber=$(($epochNumberCurrent - 1))

                        echo "Parameters missed. I gonna use $validatorIdentityPubKey from env.sh and current epoch-1 instead ($epochNumberCurrent - 1 = $epochNumber)."
                        echo "Usage: $FUNCNAME <validator_identity_pubkey> <epoch>"
                        echo "Make sure specified epoch is complete."

                else
                        validatorIdentityPubKey=$1
                        epochNumber=$2
                fi

	echo "I've got:"
	echo " Identity: $validatorIdentityPubKey"
	echo " Epoch:    $epochNumber"
	echo

        detailedEpochInfo=`curl https://api.trillium.so/validator_rewards/$epochNumber 2>/dev/null`
        echo $detailedEpochInfo | jq -r '.[] | select (.identity_pubkey=="'$validatorIdentityPubKey'")'

}


function getStakeSelf()
{
		if [[ -z $1 ]]
		then
			echo "Validator pubkey (identity) unspecified. I gonna use $validatorIdentityPubKey from env.sh instead."
			echo "Usage: $FUNCNAME <validator_identity_pubkey>"
		else
			validatorIdentityPubKey=$1
		fi
		
	echo
	$execSolana stake-account $validatorSelfstakeAccountPubkey --output json
	echo
}


function monitor()
{
	$execSolanaValidator --ledger $ledgerPath monitor
}


function restartSolanaValidator()
{

	echo

	        if [[ -z $systemSolanaService ]] || [[ "$execSolanaValidator" == "" ]]
		then
			echo "Validator system service is not specified, can not to proceed. Please check the env.sh file."
	        else

		                if [[ -z $ledgerPath ]]
				then
	                        	echo "Ledger path is not specified, please check the env.sh file."
	                        exit 0
	                	fi

				if [[ -z $execSolanaValidator ]]
				then
		                        echo "Solana validator binary file is not specified, please check the env.sh file."
	                        exit 0
	        	        fi

                	read -p " Enter max-delinquent-stake, % (5): " max_delinquent_stake
	                read -p " Enter min-idle-time, minutes (90): " min_idle_time

		                if [[ -z $max_delinquent_stake ]]
				then
	                        	echo "Maximum delinquent stake is not specified, setting it to 5%"
		                        max_delinquent_stake=5
	        	        fi

	                	if [[ -z $min_idle_time ]]
				then
		                        echo "Minimum idle time is not specified, setting it to 90 minutes"
		                        min_idle_time=90
	        	        fi

		        echo "Preparing for Solana validator restart..."
		        echo "Please, do sudo =>"
		        sudo echo "Thanks!"

		        echo ""
		        sudo $execSolanaValidator --ledger $ledgerPath wait-for-restart-window --max-delinquent-stake $max_delinquent_stake --min-idle-time $min_idle_time && sudo systemctl stop $systemSolanaService && sudo systemctl start $systemSolanaService
		fi
}



#echo -ne "Checking config ... "
#
#	if  [[ "$networkType" == "testnet" ]]; then
#
#		if [[ "$configJsonRpcUrl" == *"testnet"* && "$configWebsocketUrl" == *"testnet"* ]]; then
#                        #echo "[$colorGreen $networkType $colorEnd]"
#		else
#			export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
#			$execSolana config set --url https://api.testnet.solana.com
#			$execSolana config set --keypair $keysPath/$validatorKeyFile
#		fi
#	fi
#
#
#	if  [[ "$networkType" == "mainnet" ]]; then
#
#		if [[ "$configJsonRpcUrl" == *"mainnet"* && "$configWebsocketUrl" == *"mainnet"* ]]; then
#			#echo "[$colorGreen $networkType $colorEnd]"
#		else
#			export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
#			$execSolana config set --url https://api.mainnet-beta.solana.com
#			$execSolana config set --keypair $keysPath/$validatorKeyFile
#		fi	
#	fi
