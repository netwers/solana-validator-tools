#!/usr/bin/env bash
#
# Solana Validator failover and identity transition script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"

destinationIPAddress="0.0.0.0" # ip address of your secondary/backup server

echo "Hello!"
echo
echo "I've got this for current machine:"
echo " hostname:         $systemHostname"
echo " IP address:       $systemIPAddress"
echo " current keyFile:  $keysPath/$validatorKeyFile"
echo " unstaked keyFile: $keysPath/$validatorKeyFileUnstaked"
echo " destination:      $destinationIPAddress"


serversListFile="serversList.json"
serversListFilePath="$nodePath/$serversListFile"
sshCertsPath="$nodePath/ssh-certs"
sshCertFileName="id_rsa"
serversList=$(cat $serversListFilePath)
serverList=$(echo $serversList | jq -r  '.[] | select (.ipAddress=="'$destinationIPAddress'")')

destinationName=$(echo $serverList        | jq -r ".serverName")
destinationIPAddress=$(echo $serverList   | jq -r ".ipAddress")
destinationSSHPort=$(echo $serverList     | jq -r ".sshPort")
destinationUserName=$(echo $serverList    | jq -r ".serverUserName")
destinationSSHCertPath=$(echo $serverList | jq -r ".sshCertPath")


echo
echo "I've got this for destination machine:"
echo " hostname:         $destinationName"
echo " IP address:       $destinationIPAddress"
echo " SSH port:         $destinationSSHPort"
echo " userName:         $destinationUserName"
echo " SSH cert path:    $destinationSSHCertPath"
#echo " ledger path:      $ledgerPath"
echo

echo -n "Destination: initiating cached SSH connection ... "
execSSHRemote="ssh -p $destinationSSHPort -i $destinationSSHCertPath -f $destinationUserName@$destinationIPAddress"
result=$($execSSHRemote 'echo "true" > ~/testSSHConnection && cat ~/testSSHConnection && rm -rf ~/testSSHConnection')

	if [[ "$result" == "true" ]]; then
		echo "[$colorGreen OK $colorEnd]"
		result=""
	else 
		echo "[$colorRed FAILED $colorEnd]"
		echo "Check connection and/or auth parameters and try again."
		exit 1
		fi



execSSHRemote="ssh -p $destinationSSHPort -i $destinationSSHCertPath $destinationUserName@$destinationIPAddress"

echo -n "Destination: getting validator binary path ... "
result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && echo $execSolanaValidator')

        if [[ ! -z $result  ]]; then
                echo "[$colorGreen $result $colorEnd]"
                destinationExecSolanaValidator=$result
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check destination machine env.sh file and/or path and try again."
                exit 1
        fi

echo -n "Destination: checking validator binary path ... "
result=$($execSSHRemote "if [[ -e $destinationExecSolanaValidator ]]; then echo 'true'; else echo 'false'; fi")

        if [[ "$result" == "true" ]]; then
                echo "[$colorGreen OK $colorEnd]"
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check keyfile on destination machine and/or path and try again."
                exit 1
        fi



echo -n "Destination: getting ledger path ... "
result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && echo $ledgerPath')

        if [[ ! -z $result  ]]; then
                echo "[$colorGreen $result $colorEnd]"
		destinationLedgerPath=$result
		result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check destination machine env.sh file and/or path and try again."
                exit 1
        fi

echo -n "Destination: checking ledger path ... "
result=$($execSSHRemote "if [[ -e $destinationLedgerPath ]]; then echo 'true'; else echo 'false'; fi")

        if [[ "$result" == "true" ]]; then
                echo "[$colorGreen OK $colorEnd]"
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check keyfile on destination machine and/or path and try again."
                exit 1
        fi




echo -n "Destination: getting identity symlink path ... "
result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && echo $keysPath/$validatorKeyFile')

        if [[ ! -z $result ]]; then
                echo "[$colorGreen $result $colorEnd]"
                destinationKeyFilePath=$result
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check destination machine env.sh file and/or path and try again."
                exit 1
        fi

echo -n "Destination: checking identity symlink path ... "
result=$($execSSHRemote "if [[ -e $destinationKeyFilePath ]]; then echo 'true'; else echo 'false'; fi")

        if [[ "$result" == "true" ]]; then
                echo "[$colorGreen OK $colorEnd]"
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check keyfile on destination machine and/or path and try again."
                exit 1
        fi



echo -n "Destination: getting staked identity path ... "
result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && echo $keysPath/$validatorKeyFileStaked')

        if [[ ! -z $result ]]; then
                echo "[$colorGreen $result $colorEnd]"
                destinationKeyFileStakedPath=$result
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check destination machine env.sh file and/or path and try again."
                exit 1
        fi

echo -n "Destination: checking staked identity path ... "
result=$($execSSHRemote "if [[ -e $destinationKeyFileStakedPath ]]; then echo 'true'; else echo 'false'; fi")

        if [[ "$result" == "true" ]]; then
                echo "[$colorGreen OK $colorEnd]"
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check keyfile on destination machine and/or path and try again."
                exit 1
        fi



echo -n "Destination: getting unstaked identity path ... "
result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && echo $keysPath/$validatorKeyFileUnstaked')

        if [[ ! -z $result ]]; then
                echo "[$colorGreen $result $colorEnd]"
                destinationKeyFileUnstakedPath=$result
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check destination machine env.sh file and/or path and try again."
                exit 1
        fi

echo -n "Destination: checking unstaked identity path ... "
result=$($execSSHRemote "if [[ -e $destinationKeyFileUnstakedPath ]]; then echo 'true'; else echo 'false'; fi")

        if [[ "$result" == "true" ]]; then
                echo "[$colorGreen OK $colorEnd]"
                result=""
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check keyfile on destination machine and/or path and try again."
                exit 1
        fi


echo
echo "Destination: okay, i've got these command lines:"
echo " $destinationExecSolanaValidator -l $destinationLedgerPath set-identity $destinationKeyFileStakedPath"
echo " ln -sf $destinationKeyFileStakedPath $destinationKeyFilePath"
echo "$colorGreen Looks like we're ready. Here we go!$colorEnd"



echo -n "Local: setting identity keypair symlink to unstaked ... "
ln -sf $keysPath/$validatorKeyFileUnstaked $keysPath/$validatorKeyFile

        if [ $? -eq 0 ]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check file path and symlink and try again."
                exit 0
        fi


unixTimeStarted=`date +%s.%N`
echo -n "Local: setting identity keypair to unstaked ... "
$execSolanaValidator -l $ledgerPath set-identity $keysPath/$validatorKeyFileUnstaked

        if [ $? -eq 0 ]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check command line, connection and/or auth parameters and try again."
                exit 0
        fi


echo -n "Transfering tower file ... "
/usr/bin/rsync -a -e "ssh -p $destinationSSHPort" $ledgerPath/tower-1_9-$validatorIdentityPubKeyStaked.bin $destinationUserName@$destinationIPAddress:$destinationLedgerPath/

	if [ $? -eq 0 ]; then
		echo "[$colorGreen OK $colorEnd]"
	else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check file, connection and/or auth parameters and try again."
                exit 0
	fi

unixTimeFinished=`date +%s.%N`
secondsElapsed=`echo "$unixTimeFinished - $unixTimeStarted" | bc -l | jq '.*1000|round/1000'`
echo "Elapsed time: $secondsElapsed second(s)"
echo



echo -n "Destination: setting identity keypair to staked ... "
result=$($execSSHRemote "$destinationExecSolanaValidator -l $destinationLedgerPath set-identity --require-tower $destinationKeyFileStakedPath") 

        if [ $? -eq 0 ]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check command line, connection and/or auth parameters and try again."
                exit 0
        fi


unixTimeFinished=`date +%s.%N`
secondsElapsed=`echo "$unixTimeFinished - $unixTimeStarted" | bc -l | jq '.*1000|round/1000'`
echo "Elapsed time: $secondsElapsed second(s)"
echo



echo -n "Destination: setting identity symlink to staked ... "
result=$($execSSHRemote "ln -sf $destinationKeyFileStakedPath $destinationKeyFilePath")

        if [ $? -eq 0 ]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check command line, connection and/or auth parameters and try again."
                exit 0
        fi



echo "Done!"
echo
