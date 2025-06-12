-include .env

# The deployment script only focus on the core of the research which is mint and redeem part.

.PHONY: all test clean deploy fund help install snapshot format anvil 

SILVER_ENGINE_ADDRESS := 0x0165878A594ca255338adfa4d48449f69242Eb8F
VAULT_ENGINE_ADDRESS := 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
SILVER_ERC20_ADDRESS := 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
SILVER_NFT_ADDRESS := 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
STABLECOIN_ADDRESS :=0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
ORACLE_ADDRESS := 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9

deployMock :; forge script script/deployMock.s.sol:DeployMockPriceFeed --rpc-url $(ETH_SEPOLIA_RPC_URL) --private-key $(MAIN_SEPOLIA) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
checkMockPrice :; cast call 0x09B2D06C684772a22447Cc260001480228C1695c "latestRoundData()" --rpc-url $(ETH_SEPOLIA_RPC_URL)

deployTokenOnEthSepolia :; forge script script/deployToken.s.sol:deployToken --rpc-url $(ETH_SEPOLIA_RPC_URL) --private-key $(SECOND_SEPOLIA) --broadcast

localDeploy :; forge script script/deployEngine.s.sol:deployEngine --rpc-url http://127.0.0.1:8545 --broadcast -- private-key $(ANVIL_PRIVATE_KEY_1)

sepoliaEthDeploy :; forge script script/deployEngine.s.sol:deployEngine --rpc-url $(ETH_SEPOLIA_RPC_URL) --private-key $(MAIN_SEPOLIA) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

#================================================= BUY SILVER AND MINT ERC20 OWNERSHIP===========================================================================
AMOUNT := 10000000000000000000000 #1e22
SIXTEEN_SILVER_PRICE := 2040000000000000000000

initiateFundForBuyer :; cast send $(STABLECOIN_ADDRESS) "transfer(address,uint256)" $(ANVIL_ADDRESS_2) "$(AMOUNT)" --private-key $(ANVIL_PRIVATE_KEY_1) --rpc-url $(ANVIL_RPC_URL)

buyerApproveStableCoinTransfer :; cast send $(STABLECOIN_ADDRESS) "approve(address,uint256)" $(SILVER_ENGINE_ADDRESS) "$(SIXTEEN_SILVER_PRICE)" --private-key $(ANVIL_PRIVATE_KEY_2) --rpc-url $(ANVIL_RPC_URL)

buySilver :; cast send $(SILVER_ENGINE_ADDRESS) "buySilver(uint256)" 18 --private-key $(ANVIL_PRIVATE_KEY_2) --rpc-url $(ANVIL_RPC_URL)

#================================================= SEPOLIA ===========================================================================
S_SILVER_ENGINE_ADDRESS := 0xcD44684aa5DCBE638a1Ea8655DfDb4f04d04B549
S_VAULT_ENGINE_ADDRESS := 0xf5DD8afbDDdeced012dc063E073b1fEf77b84bD0
S_SILVER_ERC20_ADDRESS := 0xB02A7996e72ab708C8f8BD57329Bd00f152AbB26
S_SILVER_NFT_ADDRESS := 0xcFdfEC23879723e387756cf5Ca3c73f8e9fd4C09
S_STABLECOIN_ADDRESS := 0x10477d27C5F6e8494Ec118e13AB06d37Ede95d36
S_ORACLE_ADDRESS := 0x09B2D06C684772a22447Cc260001480228C1695c

sepoliaInitiateFundForBuyer :; cast send $(S_STABLECOIN_ADDRESS) "transfer(address,uint256)" $(SECOND_SEPOLIA_ADDRESS) "$(AMOUNT)" --private-key $(MAIN_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaBuyerApproveStableCoinTransfer :; cast send $(S_STABLECOIN_ADDRESS) "approve(address,uint256)" $(S_SILVER_ENGINE_ADDRESS) "$(SIXTEEN_SILVER_PRICE)" --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaBuySilver :; cast send $(S_SILVER_ENGINE_ADDRESS) "buySilver(uint256)" 18 --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaGrantAccess :; cast send $(S_SILVER_ERC20_ADDRESS) "grantRole(bytes32,address)" $(BURNER_ROLE) $(S_SILVER_ENGINE_ADDRESS) --private-key $(MAIN_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaRedeemSilver :; cast send $(S_SILVER_ENGINE_ADDRESS) "redeemSilver(uint256, string)" "$(REDEEM_IN_PRECISION)" "StoreA" --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckNftInVault :; cast call $(S_SILVER_NFT_ADDRESS) "balanceOf(address)" $(S_VAULT_ENGINE_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckNftInBuyer :; cast call $(S_SILVER_NFT_ADDRESS) "balanceOf(address)" $(SECOND_SEPOLIA_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckBuyerStableCoin :; cast call $(S_STABLECOIN_ADDRESS) "balanceOf(address)" $(SECOND_SEPOLIA_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckBuyerSilverERC20 :; cast call $(S_SILVER_ERC20_ADDRESS) "balanceOf(address)" $(SECOND_SEPOLIA_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckOraclePrice :; cast call $(S_ORACLE_ADDRESS) "latestRoundData()" --rpc-url $(ETH_SEPOLIA_RPC_URL)


#===================================== Check If Buyer StableCoin Reduce and SilverERC20 Increase ==========================================================

checkBuyerStableCoin :; cast call $(STABLECOIN_ADDRESS) "balanceOf(address)" $(ANVIL_ADDRESS_2) --rpc-url $(ANVIL_RPC_URL)

checkBuyerSilverERC20 :; cast call $(SILVER_ERC20_ADDRESS) "balanceOf(address)" $(ANVIL_ADDRESS_2) --rpc-url $(ANVIL_RPC_URL)


#=================================================== Redeem Silver  =====================================================================

BURNER_ROLE := 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848
REDEEM_IN_PRECISION := 18000000000000000000

redeemSilver :; cast send $(SILVER_ENGINE_ADDRESS) "redeemSilver(uint256, string)" "$(REDEEM_IN_PRECISION)" "StoreA" --private-key $(ANVIL_PRIVATE_KEY_2) --rpc-url $(ANVIL_RPC_URL)

checkOwnershipOfOwner :; cast call $(SILVER_NFT_ADDRESS) "balanceOf(address)" $(ANVIL_ADDRESS_2) --rpc-url $(ANVIL_RPC_URL)

checkOwnerOfNft :; cast call $(SILVER_NFT_ADDRESS) "ownerOf(uint256)" 0xc8ebba3fee22c1d1329a7a1af4f149e2b2c6f22535b8b922f856f8362f9a687b --rpc-url $(ANVIL_RPC_URL)

#================================================= REGISTER BAR ===========================================================================

define registerBar
	cast send $(VAULT_ENGINE_ADDRESS) \
		"registerBar(string,uint256,uint256,string)" \
		"$(1)" $(2) $(3) "$(4)" \
		--private-key $(ANVIL_PRIVATE_KEY_1) \
		--rpc-url $(ANVIL_RPC_URL)
endef

oneOzRegisterBar:
	$(call registerBar,SILV-1,1,999,Store A)

fiveOzRegisterBar:
	$(call registerBar,SILV-5,5,999,Store A)

tenOzRegisterBar:
	$(call registerBar,SILV-10,10,999,Store A)

fiftyOzRegisterBar:
	$(call registerBar,SILV-50,50,999,Store A)

#================================================= Check Register Success ===========================================================================

checkMetadataOneOz :; cast call $(VAULT_ENGINE_ADDRESS) "getSilverNftMetadataInDetails(uint256)" "0xb811912fb730f91b9ed2b0577bbe39d7a446cd2963f350dd5a66ff54bd47d919" --rpc-url http://127.0.0.1:8545

checkMetadataFiveOz :; cast call $(VAULT_ENGINE_ADDRESS) "getSilverNftMetadataInDetails(uint256)" "0xa901f34c748125ba8a7f8a84711a013f2d137035ee065234024c1e71dde56983" --rpc-url http://127.0.0.1:8545

checkMetadataTenOz :; cast call $(VAULT_ENGINE_ADDRESS) "getSilverNftMetadataInDetails(uint256)" "0xc8ebba3fee22c1d1329a7a1af4f149e2b2c6f22535b8b922f856f8362f9a687b" --rpc-url http://127.0.0.1:8545

checkMetadataFiftyOz :; cast call $(VAULT_ENGINE_ADDRESS) "getSilverNftMetadataInDetails(uint256)" "0x05d93995c1f4155ee828119a997f9c9926d4ef59b91650b9c8062fca398991b0" --rpc-url http://127.0.0.1:8545
