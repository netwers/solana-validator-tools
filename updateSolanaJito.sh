#!/usr/bin/env bash
#
# Solana Validator simple console "dashboard" script by Netwers, 2021-2024.
#
#

scriptPath=`cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P`
source "${scriptPath}/env.sh"
echo
date
echo

        if [[ -z $1 ]]; then
                echo "Version parameter missed."
                echo "Usage: $0 <Solana-Jito_version>"
		echo "Example: $0 1.17.31"
		exit 0
        else
                version=$1
        fi
# cd $HOME/snode/
# git clone https://github.com/jito-foundation/jito-solana

TAG="v${version}-jito"
path="${version}-jito"
echo "Version: $version"
echo "TAG: $TAG"
echo "path: $path"
echo ""
cd $nodePath/jito-solana/
git pull
git checkout tags/$TAG
git submodule update --init --recursive
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only $HOME/.local/share/solana/install/releases/$path
rm -rf $HOME/.local/share/solana/install/active_release-jito
ln -s $HOME/.local/share/solana/install/releases/$path $HOME/.local/share/solana/install/active_release-jito
ls -lha $HOME/.local/share/solana/install/
echo ""
echo "Checking..."
which agave-validator
agave-validator -V
echo
echo "Do not forget to add into you ~/.profile:"
echo 'export PATH="$HOME/.local/share/solana/install/active_release-jito/bin:$PATH"'
echo ""
