#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"

destinationIPAddress="70.34.254.112"

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
destinationLedgerPath=$ledgerPath # Your remote machine's ledger path, e.g.: /home/user/solana/ledger/. See env.sh.

echo
echo "I've got this for destination machine:"
echo " hostname:         $destinationName"
echo " IP address:       $destinationIPAddress"
echo " SSH port:         $destinationSSHPort"
echo " userName:         $destinationUserName"
echo " SSH cert path:    $destinationSSHCertPath"
echo " ledger path:      $ledgerPath"
echo

echo -n "Initiating cached SSH- connection ... "
execSSHRemote="ssh -p $destinationSSHPort -i $destinationSSHCertPath -f $destinationUserName@$destinationIPAddress"
result=$($execSSHRemote 'echo "true" > ~/testSSHConnection && cat ~/testSSHConnection && rm -rf ~/testSSHConnection')

	if [[ "$result" == "true" ]]; then
		echo "[$colorGreen OK $colorEnd]"
		result=""
	else 
		echo "[$colorRed FAILED $colorEnd]"
		echo "Check connection and/or auth parameters and try again."
		exit 0
		fi



execSSHRemote="ssh -p $destinationSSHPort -i $destinationSSHCertPath $destinationUserName@$destinationIPAddress"
#result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && $scriptPath/checkValidatorStatus.sh $validatorIdentityPubKeyStaked > ~/snode/status.txt')
echo -n "Destination: checking identity keypair ... "
result=$($execSSHRemote "if [[ -e $keysPath/$validatorKeyFileStaked ]]; then echo 'true'; else echo 'false'; fi")
#result=$($execSSHRemote 'source ~/.profile && agave-validator -V > ~/snode/status.txt')

        if [[ "$result" == "true" ]]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check keyfile on destination machine and/or path and try again."
                exit 0
        fi


echo -n "Destination: getting ledger path ... "
#result=$($execSSHRemote "if [[ -e /home/$destinationUserName/.local/share/solana/install/active_release-jito/bin/agave-validator ]]; then echo 'true'; else echo 'false'; fi")
result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && echo $ledgerPath')

echo $result
echo


exit 0
result=$($execSSHRemote "if [[ -e $ledgerPath ]]; then echo 'true'; else echo 'false'; fi")














unixTimeStarted=`date +%s.%N`

echo -n "Changing local identity keypair symlink to unstaked one ... "
#ln -sf $keysPath/$validatorKeyFileUnstaked $keysPath/$validatorKeyFile

        if [ $? -eq 0 ]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check file path and symlink and try again."
                exit 0
        fi


echo -n "Transfering tower- file ... "
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


exit 0


echo -n "Setting local validator identity to unstaked one ... "
#$execSolanaValidator -l $ledgerPath set-identity $keysPath/$validatorKeyFileUnstaked

        if [ $? -eq 0 ]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check command line, connection and/or auth parameters and try again."
                exit 0
        fi


echo -n "Setting local validator identity to staked ... "
#result=$($execSSHRemote 'source ~/.profile && source ~/snode/solana-validator-tools/env.sh && $execSolanaValidator -l $ledgerPath set-identity $keysPath/$validatorKeyFileStaked')

        if [ $? -eq 0 ]; then
                echo "[$colorGreen OK $colorEnd]"
        else
                echo "[$colorRed FAILED $colorEnd]"
                echo "Check command line, connection and/or auth parameters and try again."
                exit 0
        fi


unixTimeFinished=`date +%s.%N`
secondsElapsed=`echo "$unixTimeFinished - $unixTimeStarted" | bc -l | jq '.*1000|round/1000'
echo
echo "Done!"
