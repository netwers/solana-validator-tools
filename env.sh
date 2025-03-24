#!/usr/bin/env bash

function die ()
{
    if [ -n "$1" ]; then
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
required bc
required curl
required rsync
required ssh
required nmap

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
export sshCertsPath="$nodePath/ssh-certs"
export sshCertFileName="id_rsa"
export networkType="mainnet"
export systemSolanaService="solana-$networkType.service" #in my case of testnet: solana-testnet.service. Will add a rule.

export nodeID="1"
export rpcURL="http://localhost:8899"
configJsonRpcUrl=`${execSolana} config get json_rpc_url | awk '{print $3}'`
configWebsocketUrl=`${execSolana} config get websocket_url | awk '{print $3}'`

export nodePath="$HOME/snode"
export validatorPath="$nodePath/$networkType"
export ledgerPath="$validatorPath/ledger"
export snapshotsPath="$validatorPath/snapshots"
export accountsPath="$validatorPath/accounts"
export accounts_hash_cachePath="$validatorPath/accounts_hash_cache"
export accounts_indexPath="$validatorPath/accounts_index"
export keysPath="$nodePath/sol-keys/$networkType-$nodeID"
export notificationConfigPath="$nodePath/notificationConfig.json"
	#										#
	#  telegramBotConfig.json structure example:					#
	#										#
	#   {										#
	#   "telegramBotToken": "0123456789:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",	#
	#   "telegramChatID":   "0000000000"						#
	#   }										#
	#										#
logPath=$nodePath
logFile="journal.log"

export validatorKeyFile="validator-keypair.json"
export validatorKeyFileStaked="validator-staked-keypair.json"
export validatorKeyFileUnstaked1="validator-unstaked-1-keypair.json"
export validatorKeyFileUnstaked2="validator-unstaked-2-keypair.json"
export validatorKeyFileUnstaked3="validator-unstaked-3-keypair.json" # We have 3 mainnet servers (1x primary, 2x secondary)
export validatorKeyFileUnstaked=$validatorKeyFileUnstaked2 # default unstaked keypair for local (current) machine
export validatorVoteAccountKeyFile="vote-account-keypair.json"
export validatorIdentityPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFile`
export validatorIdentityPubKeyStaked=`${execSolanaKeygen} pubkey $keysPath/$validatorKeyFileStaked`
export validatorVoteAccountPubKey=`${execSolanaKeygen} pubkey $keysPath/$validatorVoteAccountKeyFile`
export validatorSelfstakeAccountPubkey=`cat $keysPath/selfstake-account.addr`
#export validatorBondMarinadePubkey=`cat $keysPath/bond-marinade.addr`


# functions

function checkConnectionInternet()
{
	local result=false
	local hosts=("1.1.1.1" "79.174.71.189" "www.noc.org")

	for host in "${hosts[@]}"; do
		ping -c1 $host &> /dev/null
		if [[ $? -eq 0 ]]; then
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
	local host=$1
	#echo -n "Checking connection to $host... "

	ping -c2 $host &> /dev/null
		if [[ $? -eq 0 ]]; then
			result=true
		else
			result=false
		fi

	echo $result
	return
}


function sendToLog()
{
	echo -n "Checking log path ... "

		if [ -d "$logPath" ]; then
			echo "[$colorGreen OK $colorEnd]"
		else
			echo "[$colorRed FAILED $colorEnd]"
			echo -n "First run? Creating log path ... "
			mkdir -p $logPath
			result=$?
			
				if [ $result -eq 0 ]; then
					echo "[$colorGreen OK $colorEnd]"
				else
					echo "[$colorRed FAILED $colorEnd]"
					echo "Check path, permissions, disk space and try again. Code: $result"
					sendToTelegram "$BASH_SOURCE:$FUNCNAME" "ERROR ($result): Couldn't create log path."
					exit $result
				fi
		fi

	echo -n "Checking log file ... "

		if [ -f $logPath/$logFile ]; then
			echo "[$colorGreen OK $colorEnd]"
		else
			echo "[$colorRed FAILED $colorEnd]"
	                echo -n "First run? Creating log path ... "
	                touch $logPath/$logFile
			result=$?

	                        if [ $result -eq 0 ]; then
        	                        echo "[$colorGreen OK $colorEnd]"
                	        else
                        	        echo "[$colorRed FAILED $colorEnd]"
	                                echo "Check file, permissions, disk space and try again. Code: $result"
	                                sendToTelegram "$BASH_SOURCE:$FUNCNAME" "ERROR ($result): Couldn't create log file."
	                                exit $result
	                        fi
		fi

	
		if [[ ! -z $1 ]]; then
			eventType=$1
		else
			eventType="unknown_event"
		fi


		if [[ ! -z $2 ]]; then
			eventBody=$2
		else
			eventBody="none"
		fi



	dateTimeNow=`date +"%Y-%m-%d %H:%M:%S"`
	echo "$dateTimeNow $systemHostname $BASH_SOURCE:$FUNCNAME $1 $2" >> $logPath/$logFile
}


function sendToTelegram()
{
	telegramBotToken=$(cat $notificationConfigPath | jq '.telegramBotToken' | tr -d '"')
	telegramChatID=$(cat   $notificationConfigPath | jq '.telegramChatID'   | tr -d '"')


                if [[ ! -z $1 ]]; then
                        messageTitle="$systemHostname: $1"
                else
                        messageTitle="$systemHostname: "
                fi


                if [[ ! -z $2 ]]; then
                        messageBody=$2
                else
                        messageBody="test"
                fi


	if [[ ! -z ${messageBody} ]]; then
		messageJSON=$(echo "" | awk -v TITLE="$messageTitle" -v MESSAGE="*${messageTitle}* ${messageBody}" -v CHAT_ID="$telegramChatID" '{
		print "{";
	        print "     \"chat_id\" : " CHAT_ID ","
        	print "     \"text\" : \"" MESSAGE "\","
	        print "     \"parse_mode\" : \"markdown\","
	        print "}";
	    }')

	   #echo $messageJSON
	   curl -s -d "$messageJSON" -H "Content-Type: application/json" -X POST https://api.telegram.org/bot${telegramBotToken}/sendMessage
   	else
	   curl -s --data parse_mode=HTML --data chat_id=${telegramChatID} --data text="<b>${messageTitle}</b>%0A${messageBody}" --request POST https://api.telegram.org/bot${telegramBotToken}/sendMessage
	fi
}



function sendAlert()
{
		if [[ ! -z $1 ]]; then
                        notificationBody=$1
                else
                        notificationBody="unknown"
                fi


	voipCallURI=$(cat $notificationConfigPath | jq '.voipCallURI' | tr -d '"')


		if [[ -z $voipCallURI ]]; then
			echo "Getting API URI for voip alerting ... [$colorRed FAILED $colorEnd]"
			echo "Check 'voipCallURI' value in the notification config $notificationConfigPath"
			sendNotification "ERROR" "Failed getting API URI for voip alerting. Check 'voipCallURI' value in the notification config $notificationConfigPath"
			exit $?
		else
			sendNotification "ALERT" "$notificationBody"
			result=`curl -s -v -d "solanaValidatorAlert" $voipCallURI`

				if [[ $? -eq 0 ]]; then
					sendNotification "INFO" "Call alerting successfuly initiated"
				else
					echo "There is a problem with voip alerting function. Curl request failed"
					sendNotification "ERROR" "There is a problem with voip alerting function. Curl request failed"
				fi
		fi
}



function sendNotification()
{
		if [[ ! -z $1 ]]; then
			notificationType=$1
                else
                        notificationType="INFO"
                fi
		if [[ ! -z $2 ]]; then
			notificationBody=$2
		else
			notificationBody="unknown"
		fi

	sendToTelegram "$notificationType" "$notificationBody"
	sendToLog "$notificationType" "$notificationBody"
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
