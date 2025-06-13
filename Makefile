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

#===================================== Check If Buyer StableCoin Reduce and SilverERC20 Increase ==========================================================

checkBuyerStableCoin :; cast call $(STABLECOIN_ADDRESS) "balanceOf(address)" $(ANVIL_ADDRESS_2) --rpc-url $(ANVIL_RPC_URL)

checkBuyerSilverERC20 :; cast call $(SILVER_ERC20_ADDRESS) "balanceOf(address)" $(ANVIL_ADDRESS_2) --rpc-url $(ANVIL_RPC_URL)


#=================================================== Redeem Silver  =====================================================================

BURNER_ROLE := 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848
REDEEM_IN_PRECISION := 18000000000000000000

redeemSilver :; cast send $(SILVER_ENGINE_ADDRESS) "redeemSilver(uint256, string)" "$(REDEEM_IN_PRECISION)" "StoreA" --private-key $(ANVIL_PRIVATE_KEY_2) --rpc-url $(ANVIL_RPC_URL)

checkOwnershipOfOwner :; cast call $(SILVER_NFT_ADDRESS) "balanceOf(address)" $(ANVIL_ADDRESS_2) --rpc-url $(ANVIL_RPC_URL)

checkOwnerOfNft :; cast call $(SILVER_NFT_ADDRESS) "ownerOf(uint256)" 0xc8ebba3fee22c1d1329a7a1af4f149e2b2c6f22535b8b922f856f8362f9a687b --rpc-url $(ANVIL_RPC_URL)

#========================================================== SEPOLIA ===========================================================================
S_SILVER_ENGINE_ADDRESS := 0xcD44684aa5DCBE638a1Ea8655DfDb4f04d04B549
S_VAULT_ENGINE_ADDRESS := 0xf5DD8afbDDdeced012dc063E073b1fEf77b84bD0
S_SILVER_ERC20_ADDRESS := 0xB02A7996e72ab708C8f8BD57329Bd00f152AbB26
S_SILVER_NFT_ADDRESS := 0xcFdfEC23879723e387756cf5Ca3c73f8e9fd4C09
S_STABLECOIN_ADDRESS := 0x10477d27C5F6e8494Ec118e13AB06d37Ede95d36
S_ORACLE_ADDRESS := 0x09B2D06C684772a22447Cc260001480228C1695c

sepoliaInitiateFundForBuyer :; cast send $(S_STABLECOIN_ADDRESS) "transfer(address,uint256)" $(SECOND_SEPOLIA_ADDRESS) "$(AMOUNT)" --private-key $(MAIN_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaBuyerApproveStableCoinTransfer :; cast send $(S_STABLECOIN_ADDRESS) "approve(address,uint256)" $(S_SILVER_ENGINE_ADDRESS) "$(SIXTEEN_SILVER_PRICE)" --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaBuySilver :; cast send $(S_SILVER_ENGINE_ADDRESS) "buySilver(uint256)" 18 --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaBuyFiftyFiveSilver :; cast send $(S_SILVER_ENGINE_ADDRESS) "buySilver(uint256)" 55 --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaGrantAccess :; cast send $(S_SILVER_ERC20_ADDRESS) "grantRole(bytes32,address)" $(BURNER_ROLE) $(S_SILVER_ENGINE_ADDRESS) --private-key $(MAIN_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaRedeemSilver :; cast send $(S_SILVER_ENGINE_ADDRESS) "redeemSilver(uint256, string)" "$(REDEEM_IN_PRECISION)" "StoreA" --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

#====================================================== SEPOLIA TRANSFER AND SELL ===================================================================
AMOUNT_TRANSFER := 2000000000000000000
AMOUNT_TO_SELL := 3000000000000000000
REDEEM_FIFTY_FIVE_IN_PRECISION := 50000000000000000000
FIRST_NFT_FROM_FIRST_REDEEM := 90879064225251964725523114633016714558010614405856399452748067475598740187259
NFT_ID_TO_TRANSFER := 2645367492972744220434493984444000821050354316435437773300054635882933227952
SILVER_ID_TRANSFER := "SILV-50"

sepoliaApproveERC20Transfer :; cast send $(S_SILVER_ERC20_ADDRESS) "approve(address,uint256)" $(S_SILVER_ENGINE_ADDRESS) "$(AMOUNT_TRANSFER)" --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaTransferERC20 :; cast send $(S_SILVER_ENGINE_ADDRESS) "transferERC20(address,uint256)" $(RECEIVER_ADDRESS) $(AMOUNT_TRANSFER) --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaListERC20ToSell :; cast send $(S_VAULT_ENGINE_ADDRESS) "listERC20ToSell(uint256)" $(AMOUNT_TO_SELL) --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaRedeemFiftySilver :; cast send $(S_SILVER_ENGINE_ADDRESS) "redeemSilver(uint256, string)" "$(REDEEM_FIFTY_FIVE_IN_PRECISION)" "StoreA" --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaApproveTransferNft :; cast send $(S_SILVER_NFT_ADDRESS) "approve(address,uint256)" $(S_SILVER_ENGINE_ADDRESS) $(NFT_ID_TO_TRANSFER) --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaTransferNft :; cast send $(S_SILVER_ENGINE_ADDRESS) "transferNFT(address,string)" $(RECEIVER_ADDRESS) $(SILVER_ID_TRANSFER) --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaListNftToSell :; cast send $(S_VAULT_ENGINE_ADDRESS) "listNftToSell(string)" $(SILVER_ID_TRANSFER) --private-key $(SECOND_SEPOLIA) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckNftMetadata :; cast call $(S_VAULT_ENGINE_ADDRESS) "getSilverNftMetadataInDetails(uint256)" $(FIRST_NFT_FROM_FIRST_REDEEM) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckNftInVault :; cast call $(S_SILVER_NFT_ADDRESS) "balanceOf(address)" $(S_VAULT_ENGINE_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckNftInBuyer :; cast call $(S_SILVER_NFT_ADDRESS) "balanceOf(address)" $(RECEIVER_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckBuyerStableCoin :; cast call $(S_STABLECOIN_ADDRESS) "balanceOf(address)" $(SECOND_SEPOLIA_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckBuyerSilverERC20 :; cast call $(S_SILVER_ERC20_ADDRESS) "balanceOf(address)" $(SECOND_SEPOLIA_ADDRESS) --rpc-url $(ETH_SEPOLIA_RPC_URL)

sepoliaCheckOraclePrice :; cast call $(S_ORACLE_ADDRESS) "latestRoundData()" --rpc-url $(ETH_SEPOLIA_RPC_URL)