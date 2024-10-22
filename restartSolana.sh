#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo
date

#	if [ "$EUID" -ne 0 ]
#	  then echo "Please run this script as root"
#	  exit
#	fi
#echo "Please, do sudo =>"
#sudo echo "Thanks!"

echo

	if [[ -z $systemSolanaService ]] || [[ "$execSolanaValidator" == "" ]]; then
                echo "Validator system service is not specified, can not to proceed. Please check the env.sh file."
        else

                if [[ -z $ledgerPath ]]; then
                        echo "Ledger path is not specified, please check the env.sh file."
                        exit 0
                fi
                if [[ -z $execSolanaValidator ]]; then
                        echo "Solana validator binary file is not specified, please check the env.sh file."
                        exit 0
                fi


		read -p " Enter max-delinquent-stake, % (5): " max_delinquent_stake
		read -p " Enter min-idle-time, minutes (90): " min_idle_time

                if [[ -z $max_delinquent_stake ]]; then
			echo "Maximum delinquent stake is not specified, setting it to 5%"
			max_delinquent_stake=5
                fi

                if [[ -z $min_idle_time ]]; then
                        echo "Minimum idle time is not specified, setting it to 90 minutes"
                        min_idle_time=90
                fi

	echo "Preparing for Solana validator restart..."
	echo ""
	sudo $execSolanaValidator --ledger $ledgerPath wait-for-restart-window --max-delinquent-stake $max_delinquent_stake --min-idle-time $min_idle_time && sudo systemctl stop $systemSolanaService && sudo systemctl start $systemSolanaService

	fi

