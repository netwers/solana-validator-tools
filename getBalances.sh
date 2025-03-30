#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
# Put your wallets addresses into named files to the $keysPath/addrs dir
# and do batch balance checking easily.
# e.g. echo "7qSLF8HinD2Y95Ze4dfjkVEgvxzeqBs5wT8Voc3FLCXz" > $keysPath/addrs/myWallet0.addr
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo

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
