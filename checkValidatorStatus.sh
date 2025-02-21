#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"

        if [[ -z $1 ]]; then
                echo "Validator pubkey (identity) unspecified. I gonna use $validatorIdentityPubKey from env.sh instead."
                echo "Usage: $0 <validator_identity_pubkey>"
        else
                validatorIdentityPubKey=$1
        fi

echo
date
echo

slotLeaderSchedule=`curl -s $rpcURL -X POST -H "Content-Type: application/json" -d '{
"jsonrpc": "2.0",
    "id": 1,
    "method": "getLeaderSchedule",
    "params": [
      null,
      {
        "identity": "'$validatorIdentityPubKey'"
      }
    ]
  }'`


epochInfo=`curl -s $rpcURL -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1, "method":"getEpochInfo"}'`
slotAbsolute=`echo $epochInfo | jq .result.absoluteSlot`
epochNumberCurrent=`echo $epochInfo | jq .result.epoch`
slotIndex=`echo $epochInfo | jq .result.slotIndex`
slotLeaderNext=`echo $slotLeaderSchedule | jq -r '[.result[][] | select (. > '$slotIndex')][0]'`

	if [[ "$slotLeaderNext" == "null" ]];then
		slotLeaderNext="n/a"
		slotsToLeaderNext=0
		slotsSecondsToLeaderNext=0
		slotsMinutesToLeaderNext=""
		slotsDateToLeaderNext=""
		slotsDateToLeaderNextText="n/a"
	else
		slotsToLeaderNext=$((slotLeaderNext - slotIndex))
		slotsSecondsToLeaderNext=$(($slotsToLeaderNext * 420 / 1000))
		slotsMinutesToLeaderNext=$((slotsSecondsToLeaderNext / 60))
		unixTimeNow=`date +%s`
		slotsUnixtimeToLeaderNext=$((unixTimeNow + slotsSecondsToLeaderNext))
		slotsDateToLeaderNext=`date --date="@$slotsUnixtimeToLeaderNext"`
		slotsDateToLeaderNextText="$slotsMinutesToLeaderNext minutes ~ at $slotsDateToLeaderNext"
	fi

# Let's generate actual validators json
validatorsJSON=`${execSolana} validators --output=json`
validatorJSON=`echo $validatorsJSON | jq '.validators[] | select(.identityPubkey=="'$validatorIdentityPubKey'")'`
gossipsJSON=`${execSolana} gossip --output=json`
gossipJSON=`echo $gossipsJSON | jq '.[] | select(.identityPubkey=="'$validatorIdentityPubKey'")'`
gossipVersion=`echo $gossipJSON | jq .version | tr -d '"'`
gossipIPAdress=`echo $gossipJSON | jq .ipAddress | tr -d '"'`
validatorVersionLocal=`${execSolanaValidator} --version | awk '{print $2}'`
validatorVersionNet=`echo $validatorJSON | jq .version | tr -d '"'`
validatorActivatedStake=`echo $validatorJSON | jq '.activatedStake / 1000000000 | round'`
validatorDelinquent=`echo $validatorJSON | jq '.delinquent'`
versionsCheck="$colorRed❌$colorEnd"

	if [[ -z $validatorVersionNet ]]; then
		validatorVersionNet=$gossipVersion
	fi


	if [[ "$validatorVersionLocal" == "$validatorVersionNet" ]];then
		versionsCheck="$colorGreen✅$colorEnd"
	fi

echo  "Network:     $networkType" #($rpcURL)"
echo  "Version:     $validatorVersionLocal (local) $versionsCheck $validatorVersionNet (network)"
echo  "Validator:   $validatorIdentityPubKey"
echo  "Vote:        $validatorVoteAccountPubKey"
echo

epoch=`${execSolana} epoch-info --url $rpcURL --output json`
epochProgress=`${execSolana} epoch-info --url $rpcURL | grep "Epoch Completed Percent:" | awk '{print $4}'`

echo "Epoch:"
echo " Number: $epochNumberCurrent"
echo " Completed: $epochProgress"

slotsScheduled=`${execSolana} leader-schedule | grep $validatorIdentityPubKey | wc -l`
slotsBuilt=`${execSolana} block-production --url $rpcURL | grep -e $validatorIdentityPubKey | awk '{print $2}'`

	if [[ ! -z $slotsBuit ]] || [[ "$slotsBuilt" == "" ]];then
		slotsBuilt=0
	fi

let slotsRemaining=$slotsScheduled-$slotsBuilt
slotsSkipped=`${execSolana} block-production --url $rpcURL | grep -e $validatorIdentityPubKey | awk '{print $4}'`
slotsSigned=`${execSolana}  block-production --url $rpcURL | grep -e $validatorIdentityPubKey | awk '{print $3}'`

	if [[ -z $slotsSigned ]]; then
	        slotsSigned=0
	fi

	if [[ -z $slotsSkipped ]]; then
	        slotsSkipped=0
	fi

echo " Scheduled: $slotsScheduled"
echo " Built:     $slotsBuilt"
echo " Signed:    $colorGreen$slotsSigned$colorEnd"
echo " Skipped:   $colorRed$slotsSkipped$colorEnd"
echo " Remaining: $slotsRemaining"

# Skiprate checking
skipInfo=`${execSolana} block-production --url $rpcURL | grep -e $validatorIdentityPubKey`
skipPercent=`echo $skipInfo | gawk '{print $NF}'`
skipPercent=${skipPercent%"%"}
skipTotal=`${execSolana} block-production --url $rpcURL | grep -e total`
skipPercentTotal=`echo $skipTotal | gawk '{print $NF}'`
skipPercentTotal=${skipPercentTotal%"%"}

	if [[ -z $skipPercent ]]; then
                skipPercent=0
	fi

echo " Skip rate: $skipPercent%"
echo " Skip net:  $skipPercentTotal%"
echo ""

validatorCreditsTotal=`${execSolana} vote-account --url $rpcURL $validatorVoteAccountPubKey --output=json | jq .epochVotingHistory[-1].creditsEarned`
echo " Credits:    ${validatorCreditsTotal}"
validatorPosition=`${execSolana} validators --url $rpcURL --sort=credits -r -n | grep  -e $validatorIdentityPubKey | awk '{print $1}'`
validatorsPositions=`${execSolana} validators --url $rpcURL --sort=credits -r -n | grep SOL -c`
echo " Position:   $validatorPosition / $validatorsPositions"
echo -n " Delinquent: "

	if [[ "$validatorDelinquent" == "false" ]]; then
		echo "$colorGreen$validatorDelinquent$colorEnd"
	else
		echo "$colorRed$validatorDelinquent$colorEnd"
	fi

echo ""

echo "Slots:"
echo " Current:  $slotIndex"
echo " Next:     $slotLeaderNext"
echo " Next in:  $slotsDateToLeaderNextText"
echo " Slots to: $slotsToLeaderNext"

balanceValidator=`${execSolana} balance --url $rpcURL $validatorIdentityPubKey | awk '{print $1}' | jq '.*100|round/100'`
balanceVoteAccount=`${execSolana} balance --url $rpcURL $validatorVoteAccountPubKey | awk '{print $1}' | jq '.*100|round/100'`
balanceBondMarinade=`${execSolana} balance --url $rpcURL $validatorBondMarinadePubkey | awk '{print $1}' | jq '.*100|round/100'`
echo


echo "Balance:"

compare() (IFS=" "
  exec awk "BEGIN{if (!($*)) exit(1)}"
)

	if compare "$balanceValidator < 1"; then
		echo " Validator:    $colorRed$balanceValidator$colorEnd"
		else echo " Validator:    $balanceValidator"
	fi

echo " Vote account: $balanceVoteAccount"

        if compare "$balanceBondMarinade < 1"; then
                echo " Bond:         $colorRed$balanceBondMarinade$colorEnd"
                else echo " Bond:         $balanceBondMarinade"
        fi


	if  [[ "$networkType" == "mainnet" ]]; then
		balanceSelfStaked=`${execSolana} stake-account $validatorSelfstakeAccountPubkey --output json | jq .activeStake | jq './10000000|round/100'`
		balanceSelfStakedUSDT=`echo $balanceSelfStaked | jq ".*$solanaPrice|round"`
		echo " Total staked: $validatorActivatedStake"
                echo " SOL/USDT:     $colorGreen$solanaPrice$colorEnd"
		echo " Self staked:  $balanceSelfStaked ($colorGreen"USDT" $balanceSelfStakedUSDT$colorEnd)"
	fi

unixtime=`date +%s`;
echo
echo "$unixtime $epochNumberCurrent $epochProgress $slotsScheduled $slotsBuilt $slotsSkipped $slotsRemaining $balanceValidator $balanceVoteAccount" >> $logPath/balances-$networkType.log
date
echo
