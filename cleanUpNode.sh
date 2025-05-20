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
                fi
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
                                echo -n "Stopping solana service ($systemSolanaService) ... "
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
                                [yY] ) echo -n "Removing snapshots ... ";

					rm -rf $snapshotsPath/*

						if [[ $? -eq 0 ]]
		                                then
	        	                                echo "[$colorGreen OK $colorEnd]" >&2
	                	                else
	                        	                echo "[$colorRed FAILED $colorEnd]" >&2
		                                fi


					echo -n "Removing incremental snapshots ... ";

					rm -rf $snapshotsIncrementalPath/*

						if [[ $? -eq 0 ]]
        	                	        then
        	        	                        echo "[$colorGreen OK $colorEnd]" >&2
                		                else
        	                	                echo "[$colorRed FAILED $colorEnd]" >&2
		                                fi
					;;

                                [nN] ) echo "Proceeding without deleting snapshots ... ";
                                        ;;

                                * ) echo "Invalid response";;
                        esac

                        echo -n "Removing accounts, indexes and hashes ... ";
                        rm -rf $accountsPath*/*
			
				if [[ $? -eq 0 ]]
                                then
                                        echo "[$colorGreen OK $colorEnd]" >&2
                                else
                                        echo "[$colorRed FAILED $colorEnd]" >&2
                                fi



                        echo -n "Removing ledger, but keeping contact-info.bin, genesis.bin, genesis.tar.bz2 and tower- file ... ";

			find $ledgerPath/ -depth ! -name contact-info.bin ! -name genesis.bin ! -name genesis.tar.bz2 ! -name tower-1_9-$validatorIdentityPubKeyStaked.bin -type d,f,s -print
                        #rm -rf $ledgerPath/*

				if [[ $? -eq 0 ]]
                                then
                                        echo "[$colorGreen OK $colorEnd]" >&2
                                else
                                        echo "[$colorRed FAILED $colorEnd]" >&2
                                fi


			echo -n "Trim is processing ... "

				if [[ $? -eq 0 ]]
				then
					echo "[$colorGreen OK $colorEnd]" >&2
				else
					echo "[$colorRed FAILED $colorEnd]" >&2
				fi

        fi

echo "Done"
