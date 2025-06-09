-include .env

deployTokenOnEthSepolia :; forge script script/deployToken.s.sol:deployToken --rpc-url $(ETH_SEPOLIA_RPC_URL) --private-key $(SECOND_SEPOLIA) --broadcast