#!/usr/bin/env bash
#
# Solana Validator tool script by Netwers, 2022-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"


	if [[ -z $1 ]]; then
		echo "Vote account unspecified. I gonna use $validatorVoteAccountPubKey from env.sh instead."
		echo "Usage: $0 <vote_account_addr>"
	else
		validatorVoteAccountPubKey=$1
	fi

validatorsJSON=`${execSolana} validators --output=json`
gossipJSON=`${execSolana} gossip --output=json`
validatorIdentityPubKey=`echo $validatorsJSON | jq '.validators[] | select (.voteAccountPubkey=="'$validatorVoteAccountPubKey'").identityPubkey' | tr -d "\""`
ipAddress=`echo $gossipJSON | jq '.[] | select (.identityPubkey=="'$validatorIdentityPubKey'").ipAddress' | tr -d "\""`

echo $ipAddress >> $logPath/ipAddress-$validatorVoteAccountPubKey.txt
whois $ipAddress

echo "vote:     $validatorVoteAccountPubKey"
echo "identity: $validatorIdentityPubKey"
echo "IP:       $ipAddress"
echo
