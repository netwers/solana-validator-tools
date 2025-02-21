# Just a note. Two steps.
#1 validator-bonds -um init-withdraw-request $validatorVoteAccountPubKey --authority $keysPath/bond-marinade.json --amount ALL --keypair $keysPath/validator-staked-keypair.json
#2 validator-bonds -um claim-withdraw-request $withdrawRequestPubkey --authority $keysPath/bond-marinade.json --withdrawer $keysPath/validator-staked-keypair.json --keypair $keysPath/validator-staked-keypair.json
