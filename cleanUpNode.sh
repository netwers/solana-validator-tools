#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo
date


        if [[ -z $validatorPath ]] || [[ "$validatorPath" == "" ]]; then
		echo "Validator path is not specified, can not to proceed. Please check it in env.sh file."
	else

		if [[ -z $snapshotsPath ]]; then
			echo "Snapshots path is not specified, please check it in env.sh file."
			exit 0
                if [[ -z $snapshotsIncrementalPath ]]; then
                        echo "Snapshots path is not specified, please check it in env.sh file."
                        exit 0			
		fi
		if [[ -z $accountsPath ]]; then
                        echo "Accounts path is not specified, please check it in env.sh file."
                        exit 0
                fi
                if [[ -z $accounts_hash_cachePath ]]; then
                        echo "Accounts hash cache path is not specified, please check it in env.sh file."
                        exit 0
		fi
		if [[ -z $accounts_indexPath ]]; then
                        echo "Accounts path is not specified, please check it in env.sh file."
                        exit 0			
                fi
                if [[ -z $ledgerPath ]]; then
                        echo "Ledger path is not specified, please check it in env.sh file."
                        exit 0
                fi


		systemSolanaServiceStatus=`systemctl is-active $systemSolanaService`

			if [[ "$systemSolanaServiceStatus" == "active" ]]; then
				echo -n "Stopping solana service ($systemSolanaService)... "
				sudo systemctl stop $systemSolanaService

				systemSolanaServiceStatus=`systemctl is-active $systemSolanaService`
				
					if [[ "$systemSolanaServiceStatus" == "failed" ]]; then
						echo "[$colorGreen OK $colorEnd]"
					else
						echo "Service $systemSolanaService is still running, can not to proceed."
						exit 0
					fi
			fi

                        read -p "Do you want to delete snapshots also? (y/n) " yn
                        case $yn in
				[yY] ) echo -n "Removing snapshots... ";
					echo "[$colorGreen OK $colorEnd]"
					rm -rf $snapshotsPath/*
					rm -rf $snapshotsIncrementalPath/*
					;;

                                [nN] ) echo "Proceeding without deleting snapshots...";
					;;

                                * ) echo "Invalid response";;
                        esac
			
			echo -n "Removing accounts... ";
			rm -rf $accountsPath/*
			echo "[$colorGreen OK $colorEnd]"

			echo -n "Removing accounts hashes... ";
			rm -rf $accounts_hash_cachePath/*
			echo "[$colorGreen OK $colorEnd]"

                        echo -n "Removing accounts index... ";
                        rm -rf $accounts_indexPath/*
                        echo "[$colorGreen OK $colorEnd]"

			echo -n "Removing ledger... ";
			rm -rf $ledgerPath/*
			echo "[$colorGreen OK $colorEnd]"

	fi

echo "Done"
