#!/usr/bin/env bash
#
# Solana Validator Automated Failover script by Netwers®️, ©️2021-2026
# 
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"

echo
date +"%Y-%m-%d %H:%M:%S"
echo
echo "Solana Validator Automated Failover is starting up:"
echo
echo " Welcome, $USER!"
echo " Terminal: $TERM"
echo " Connected: $SSH_CLIENT"
echo
echo -n "Checking paths ... "

	if [ -d "$sshCertsPath" ]; then
		echo "[$colorGreen OK $colorEnd]"
	else
		echo "[$colorRed FAILED $colorEnd]"
		echo -n "Creating ssh certs/keys directory $sshCertsPath ... "
		mkdir -p $sshCertsPath

			if [ -d "$sshCertsPath" ]; then
				echo "[$colorGreen OK $colorEnd]"
			else
				echo "[$colorRed FAILED $colorEnd]"
				exit 0
			fi
	fi


echo -n "Gathering local server data ... "

        if [[ -z $systemIPAddress ]]; then
		echo "[$colorRed FAILED (IP) $colorEnd]"
                exit 0
	fi

        if [[ -z $systemSSHPort ]]; then
                echo "[$colorRed FAILED (SSH) $colorEnd]"
                exit 0
        fi

echo "[$colorGreen OK $colorEnd]"
echo
echo " hostname: $systemHostname"
echo " ip:       $systemIPAddress"
echo " ssh port: $systemSSHPort"
echo



echo -n "Checking servers list file ... "

	if [ ! -f $serversListFilePath ]; then
		echo "[$colorRed $serversListFilePath NOT FOUND $colorEnd]"
		exit 0
	else
		echo "[$colorGreen OK $colorEnd]"
		serversList=$(cat $serversListFilePath)
	fi



echo -n "Checking Internet connection ... "
connectionInternet=$(checkConnectionInternet)

        if [[ "$connectionInternet" == "true" ]]; then
                echo "[$colorGreen OK $colorEnd]"
                yq e -i -o json '(.[] | select (.serverName=="'$systemHostname'").online) = "true"' $serversListFilePath
        else
                echo "[$colorRed FAILED $colorEnd]"
		yq e -i -o json '(.[] | select (.serverName=="'$systemHostname'").online) = "false"' $serversListFilePath
        fi

sleep 1



echo -n "Searching local server in the list ... "
isLocalServerExist=$(echo $serversList | jq  '.[] | select (.serverName=="'$systemHostname'")')

        if [[ -z $isLocalServerExist ]]; then
		echo "[$colorYellow NOT FOUND $colorEnd]"

		while true; do
			read -p "Do you want me to add your server data into servers list? (y/n) " yn
			case $yn in
				[yY] ) echo -n "Adding new server's entry into $serversListFilePath ... ";

					serversListCount=$(echo $serversList | jq -r  '. | length')

					if [[ $serversListCount -gt 0 ]] && [[ "$serversListCount" != "" ]]; then
						#serversListNewEntryNumber=$((serversListCount + 1))
						serversListNewEntryNumber=$serversListCount
					else serversListNewEntryNumber=0
					fi

					unixTimeNow=`date +%s`
					serversListNewEntry='
					{
						"serverName": "'$systemHostname'",
						"ipAddress": "'$systemIPAddress'",
						"sshPort": "'$systemSSHPort'",
						"sshCert": null,
						"online": "yes",
						"ping": null,
						"sshConnection": "ok",
						"systemUsageRAM": null,
						"systemUsageCPU": null,
						"systemUsageStorageLedger": null,
						"systemUsageStorageAccounts": null,
						"validator": null,
						"delinquent": null,
						"catchup": null,
						"localServer" : "true",
						"updatedUnixtime": "'$unixTimeNow'"
					}'
					yq -i -o json ".["$serversListNewEntryNumber"] += $serversListNewEntry" $serversListFilePath					
					echo "[$colorGreen OK $colorEnd]"
					echo -n "Reading updated servers list ... "
					serversList=$(cat $serversListFilePath)

					echo "[$colorGreen OK $colorEnd]"
					break;;

				[nN] ) echo "Proceeding without adding local server's data...";
					break;;

				* ) echo "Invalid response";;
			esac
		done

	else
		echo "[$colorGreen FOUND $colorEnd]"
		echo -n "Checking .localServer value ... "
		result=""
		result=$(echo $serversList | jq -r '.[] | select (.serverName=="'$systemHostname'").localServer')

			if [[ "$result" == "true" ]]; then
                                echo "[$colorGreen OK $colorEnd]"
                        else
                                echo "[$colorRed FAILED $colorEnd]"
				echo -n "Updating .localServer value ..."
                                yq e -i -o json '(.[] | select (.serverName=="'$systemHostname'").localServer) = "true"' $serversListFilePath
				yq e -i -o json '(.[] | select (.serverName!="'$systemHostname'").localServer) = "false"' $serversListFilePath
				echo "[$colorGreen OK $colorEnd]"
				echo -n "Reading updated servers list ... "
				serversList=$(cat $serversListFilePath)
                                echo "[$colorGreen OK $colorEnd]"
                        fi	
        fi


echo -n "Getting count of servers ... "
serversListCount=$(echo $serversList | jq -r  '. | length')

	if [[ "$serversListCount" == "null" ]] || [[ "$serversListCount" == "" ]] || [[ $serversListCount -eq 0 ]]; then
		echo "[$colorRed 0 $colorEnd]"
		echo "I can not proceed with no servers in list, please add atleast 2 into $serversListFilePath to failover able to function."
		exit 0
	fi

	if [[ $serversListCount -eq 1 ]]; then
		echo "[$colorRed 1 $colorEnd]"
		echo "I can not proceed with only one server, please add atleast 1 remote server into $serversListFilePath to failover able to function."
		exit 0
	fi

	if [[ $serversListCount -gt 1 ]]; then
		echo "[$colorGreen $serversListCount $colorEnd]"
	fi

echo "Updating servers data... "

c=0
	for i in $(seq $serversListCount)
	do
		serverName=$(echo $serversList | jq -r ".[$c].serverName")
		serverIPAddress=$(echo $serversList | jq -r ".[$c].ipAddress")
		serverSSHPort=$(echo $serversList | jq -r ".[$c].sshPort")
		serverUserName=$(echo $serversList | jq -r ".[$c].serverUserName")
		serverLocalServer=$(echo $serversList | jq -r ".[$c].localServer")
		serverSSHCertPath=$(echo $serversList | jq -r ".[$c].sshCertPath")

		echo
		echo "Processing server $c: $serverName, $serverIPAddress:$serverSSHPort, local server: $serverLocalServer"


		echo -n " Checking ICMP connection ... "
                result=""
		result=$(checkConnectionHost $serverIPAddress)
		
			if [[ "$result" == "true" ]]; then
				echo "[$colorGreen OK $colorEnd]"
				yq e -i -o json '(.[] | select (.serverName=="'$serverName'").ping) = "ok"' $serversListFilePath
				serverPing="ok"
			else
				echo "[$colorRed FAILED $colorEnd]"
				yq e -i -o json '(.[] | select (.serverName=="'$serverName'").ping) = "failed"' $serversListFilePath
				serverPing="failed"
			fi



		echo -n " Checking SSH port open ... "
		result=""
		result=$($execNmap $serverIPAddress -PN -p $serverSSHPort | egrep 'open|closed|filtered' | awk '{print $2}')

			if [[ "$result" == "open" ]]; then
                                echo "[$colorGreen OK $colorEnd]"
				yq e -i -o json '(.[] | select (.serverName=="'$serverName'").sshPortStatus) = "ok"' $serversListFilePath
				serverSSHPortStatus="ok"
                        else
                                echo "[$colorRed FAILED $colorEnd]"
                                yq e -i -o json '(.[] | select (.serverName=="'$serverName'").sshPortStatus) = "failed"' $serversListFilePath
				serverSSHPortStatus="failed"
                        fi
			


		echo -n " Checking SSH cert/key ... "

		if [[ "$serverSSHPortStatus" != "failed" ]]; then

			if [[ "$serverLocalServer" != "true" ]]; then

				if [[ "$serverSSHCertPath" == "false" ]] || [[ "$serverSSHCertPath" == "" ]] || [[ "$serverSSHCertPath" == null ]] || [ ! -f "$sshCertsPath/$serverName/$sshCertFileName" ] ; then

					echo "[$colorRed N/A $colorEnd]"
					echo -n " Searching cert/key file $sshCertFileName in $sshCertsPath/$serverName ... "

					if [ -f "$sshCertsPath/$serverName/$sshCertFileName" ]; then
						echo "[$colorGreen FOUND $colorEnd]"

						echo -n " Checking cert/key file permissions ... "

							if [[ $(stat -L -c "%a" $sshCertsPath/$serverName/$sshCertFileName) == "600" ]]; then
								echo "[$colorGreen OK $colorEnd]"
							else
								echo echo "[$colorRed $(stat -L -c "%a" $sshCertsPath/$serverName/$sshCertFileName) $colorEnd]"
								echo -n " Setting new (600) cert/key file permissions ... "
								chmod 600 $sshCertsPath/$serverName/$sshCertFileName

									if [[ $(stat -L -c "%a" $sshCertsPath/$serverName/$sshCertFileName) == "600" ]]; then
		                                                                echo "[$colorGreen OK $colorEnd]"
									else
										echo "[$colorRed FAILED $colorEnd]"
										exit 0
									fi
							fi


						echo -n " Storing file name and path into servers list ... "
						yq e -i -o json '(.[] | select (.serverName=="'$serverName'").sshCertPath) = "'$sshCertsPath/$serverName/$sshCertFileName'"' $serversListFilePath
						echo "[$colorGreen OK $colorEnd]"

						echo -n " Reading updated servers list ... "
						serversList=$(cat $serversListFilePath)
						echo "[$colorGreen OK $colorEnd]"

					else
						echo "[$colorRed NOT FOUND $colorEnd]"

						echo -n " Checking path $sshCertsPath/$serverName ... "
							
							if [ -d "$sshCertsPath/$serverName" ]; then
								echo "[$colorGreen OK $colorEnd]"
							else
								echo "[$colorRed FAILED $colorEnd]"
								echo -n " Creating ssh certs/keys directory $sshCertsPath/$serverName ... "
								mkdir -p $sshCertsPath/$serverName

									if [ -d "$sshCertsPath/$serverName" ]; then
										echo "[$colorGreen OK $colorEnd]"
										echo "$colorYellow Please put ssh cert/key file to the path: $sshCertsPath/$serverName/ with file name: $sshCertFileName! $colorEnd"
										echo "$colorYellow Please transfer pubkey file to the server $serverName in the user's authorized_keys file. $colorEnd"

									else
										echo "[$colorRed FAILED $colorEnd]"
										echo " $colorYellow Please check/create your paths manually! $colorEnd"
										exit 0
									fi
							fi
							
							while true; do
								read -p " Do you want to configure sshd server on this server and generate ssh cert/key? (y/n) " yn
								case $yn in
									[yY] ) echo " Using server username: [$colorGreen $serverUserName $colorEnd]"

										result=""
										result=$(ssh -p $serverSSHPort $serverUserName@$serverIPAddress 'if [ "$(cat /etc/ssh/sshd_config | grep -iwc "HostbasedUsesNameFromPacketOnly yes")" -gt 0 ]; then echo "true"; else echo "false"; fi;')
										echo -n " Checking sshd config on server ... ";

											if [[ "$result" == "true" ]]; then
												echo "[$colorGreen OK $colorEnd]"
                                                                                        else
                                                                                                echo "[$colorRed INCOMPLETE $colorEnd]"
                                                                                                echo " Adding 'HostbasedUsesNameFromPacketOnly yes' to sshd config ... ";
												result=""
												result=$(ssh -p $serverSSHPort $serverUserName@$serverIPAddress 'sudo -S sed -i "$ a\HostbasedUsesNameFromPacketOnly yes" /etc/ssh/sshd_config && sudo -S systemctl restart sshd && if [ "$(cat /etc/ssh/sshd_config | grep -iwc "HostbasedUsesNameFromPacketOnly yes")" -gt 0 ]; then echo "true"; else echo "false"; fi;')
												echo -n " Adding 'HostbasedUsesNameFromPacketOnly yes' to sshd config ... ";

													if [[ "$result" == "true" ]]; then
														echo "[$colorGreen OK $colorEnd]"
													else
														echo "[$colorRed FAILED $colorEnd]"
														echo " $colorYellow Please check your sshd_config manually! $colorEnd"
														exit 0
													fi
                                                                                        fi

                                                                                echo " Generating local ssh cert/key into $sshCertsPath/$serverName/$sshCertFileName..."
                                                                                read -p " Enter target $serverName's username which this cert/key will be added to: " serverKeyUserName
                                                                                echo " Username: [$colorGreen $serverKeyUserName $colorEnd]"
                                                                                ssh-keygen -f $sshCertsPath/$serverName/$sshCertFileName
                                                                                chmod 600 $sshCertsPath/$serverName/$sshCertFileName
                                                                                echo " Trasnfering ssh pubkey file to the server $serverName..."
                                                                                ssh-copy-id -i $sshCertsPath/$serverName/$sshCertFileName -p $serverSSHPort $serverKeyUserName@$serverIPAddress
										echo " $colorYellowPlease restart $0 to apply new parameters $colorEnd"
										exit 0
										
										break;;
									[nN] ) echo " Proceeding without adding cert/key...";
										break;;
									* ) echo " Invalid response";;
								esac
							done

					fi
				
				else
					execSSHRemote="ssh -p $serverSSHPort -i $serverSSHCertPath $serverUserName@$serverIPAddress"

					echo "[$colorGreen OK $colorEnd]"
					echo -n " Checking SSH connection using ssh cert/key ... "
					result=""
					result=$($execSSHRemote 'echo "true" > ~/testSSHConnection && cat ~/testSSHConnection && rm -rf ~/testSSHConnection')

						if [[ "$result" == "true" ]]; then
							echo "[$colorGreen OK $colorEnd]"
							yq e -i -o json '(.[] | select (.serverName=="'$serverName'").sshConnection) = "ok"' $serversListFilePath
							serverSSHConnection="ok"
						else
							echo "[$colorRed FAILED $colorEnd]"
							yq e -i -o json '(.[] | select (.serverName=="'$serverName'").sshConnection) = "failed"' $serversListFilePath
                                                	echo " $colorYellow Please check ssh connection manually! $colorEnd"
							serverSSHConnection="failed"
						fi

					fi
				else
					echo "[$colorGreen LOCAL SERVER $colorEnd]"
				fi
			else
				echo "[$colorYellow SKIPPED $colorEnd]"
				yq e -i -o json '(.[] | select (.serverName=="'$serverName'").sshConnection) = "skipped"' $serversListFilePath
			fi


			echo -n " Setting online status ... "

			if [[ "$serverLocalServer" != "true" ]]; then

				if [[ "$serverPing" == "ok" && "$serverSSHPortStatus" == "ok" && "$serverSSHConnection" == "ok" ]]; then
					echo "[$colorGreen TRUE $colorEnd]"
					yq e -i -o json '(.[] | select (.serverName=="'$serverName'").online) = "true"' $serversListFilePath
					serverOnlineStatus="true"
				else
					echo "[$colorRed FALSE $colorEnd]"
					yq e -i -o json '(.[] | select (.serverName=="'$serverName'").online) = "false"' $serversListFilePath
					serverOnlineStatus="false"
				fi
			else
				 echo "[$colorGreen SKIPPED $colorEnd]"
			fi



		serverSystemUsageCPU=""
		serverSystemUsageRAM=""
		serverSystemUsageStorageLedger=""
		serverSystemUsageStorageAccounts=""

		echo -n " Checking CPU usage ... "

			if [[ "$serverLocalServer" == "true" ]]; then
				#serverSystemCPUUsage=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1) "%"; }' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat))
				serverSystemUsageCPU=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf ("%.0f", ($2+$4-u1) * 100 / (t-t1));}' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat))
				echo "[$colorGreen $serverSystemUsageCPU% $colorEnd]"
			else
				if [[ "$serverOnlineStatus" == "true" ]]; then
					serverSystemUsageCPU=$($execSSHRemote 'awk '\''{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf ("%.0f", ($2+$4-u1) * 100 / (t-t1));}'\'' <(grep "cpu " /proc/stat) <(sleep 1;grep "cpu " /proc/stat)')
					echo "[$colorGreen $serverSystemUsageCPU% $colorEnd]"
				else
					echo "[$colorYellow SKIPPED $colorEnd]"
				fi
			fi

			yq e -i -o json '(.[] | select (.serverName=="'$serverName'").systemUsageCPU) = "'$serverSystemUsageCPU'"' $serversListFilePath



		echo -n " Checking RAM usage ... "

			if [[ "$serverLocalServer" == "true" ]]; then
                                serverSystemUsageRAM=$(printf "%.0f" $(echo "scale=2; $(awk '/MemAvailable/ { printf "%.0f", $2/1024/1024 }' /proc/meminfo) / $(awk '/MemTotal/ { printf "%.0f", $2/1024/1024 }' /proc/meminfo) * 100" | bc))
				echo "[$colorGreen $serverSystemUsageRAM% $colorEnd]"
                        else
				if [[ "$serverOnlineStatus" == "true" ]]; then
					serverSystemUsageRAM=$($execSSHRemote 'printf "%.0f" $(echo "scale=2; $(awk '\''/MemAvailable/ { printf "%.0f", $2/1024/1024 }'\'' /proc/meminfo) / $(awk '\''/MemTotal/ { printf "%.0f", $2/1024/1024 }'\'' /proc/meminfo) * 100" | bc)')
					echo "[$colorGreen $serverSystemUsageRAM% $colorEnd]"
				else
					echo "[$colorYellow SKIPPED $colorEnd]"
				fi
                        fi

                        yq e -i -o json '(.[] | select (.serverName=="'$serverName'").systemUsageRAM) = "'$serverSystemUsageRAM'"' $serversListFilePath



		echo -n " Checking ledger disk usage ... "

                        if [[ "$serverLocalServer" == "true" ]]; then
                                serverSystemUsageStorageLedger=$(df $ledgerPath | grep dev | awk '{print $5}' | tr -d "%")
				echo "[$colorGreen $serverSystemUsageStorageLedger% $colorEnd]"
                        else
				if [[ "$serverOnlineStatus" == "true" ]]; then
					serverSystemUsageStorageLedger=$($execSSHRemote 'df '$ledgerPath' | grep dev | awk '\''{print $5}'\'' | tr -d "%"')
					echo "[$colorGreen $serverSystemUsageStorageLedger% $colorEnd]"
                                else
                                        echo "[$colorYellow SKIPPED $colorEnd]"
                                fi
                        fi

                        yq e -i -o json '(.[] | select (.serverName=="'$serverName'").systemUsageStorageLedger) = "'$serverSystemUsageStorageLedger'"' $serversListFilePath



                echo -n " Checking accounts disk usage ... "

                        if [[ "$serverLocalServer" == "true" ]]; then
                                serverSystemUsageStorageAccounts=$(df $accountsPath | grep dev | awk '{print $5}' | tr -d "%")
				echo "[$colorGreen $serverSystemUsageStorageAccounts% $colorEnd]"
                        else
                                if [[ "$serverOnlineStatus" == "true" ]]; then
					serverSystemUsageStorageAccounts=$($execSSHRemote 'df '$accountsPath' | grep dev | awk '\''{print $5}'\'' | tr -d "%"')
					echo "[$colorGreen $serverSystemUsageStorageAccounts% $colorEnd]"
                                else
                                        echo "[$colorYellow SKIPPED $colorEnd]"
                                fi
			fi

                        yq e -i -o json '(.[] | select (.serverName=="'$serverName'").systemUsageStorageAccounts) = "'$serverSystemUsageStorageAccounts'"' $serversListFilePath



		unixTimeNow=`date +%s`
                yq e -i -o json '(.[] | select (.serverName=="'$serverName'").updatedUnixtime) = "'$unixTimeNow'"' $serversListFilePath

		c=$(($c + 1))
	done

	echo
	echo "[$colorGreen Servers data processing completed! $colorEnd]"
	echo


