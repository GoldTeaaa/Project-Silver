# Silver Tokenization and Redemption via Smart Contracts

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Tests](https://github.com/your-repo/silver-tokenization/actions/workflows/tests.yml/badge.svg)](https://github.com/your-repo/silver-tokenization/actions)

## 🪙 Overview

This project enables the tokenization and redemption of physical silver using Ethereum-based smart contracts. It ensures secure, transparent, and globally verifiable ownership through a hybrid dual-token system:

- **ERC20 token (`SilverERC20`)** for fungible silver ownership (1 token = 1 gram/oz).
- **ERC721 token (`SilverNFT`)** minted only during redemption to represent unique physical silver bars.

The system is fully on-chain, with all silver bar metadata, availability status, and redemption logic handled by smart contracts.

---

## 🧱 Architecture

### Contracts Overview

- **`SilverERC20.sol`**  
  Inherits OpenZeppelin's ERC20. Represents fungible silver. Minting and burning are restricted via `MINTER_ROLE` and `BURNER_ROLE`.

- **`SilverNFT.sol`**  
  Inherits OpenZeppelin's ERC721. Represents individual physical silver bars. Each token includes metadata: vault ID, bar weight, and serial number.

- **`VaultEngine.sol`**  
  Acts as the central manager. Handles:
  - Burning ERC20 tokens.
  - Assigning vault bars.
  - Minting ERC721 tokens with correct metadata.

### Redemption Flow

1. User calls `redeem(uint256 amount)` in `VaultEngine`.
2. The specified `amount` of `SilverERC20` is burned.
3. Vault availability is checked.
4. ERC721 tokens are minted with exact matched weight, bar serial number, and vault location.

---

## 🧬 Folder Structure

```
/contracts
  ├── SilverERC20.sol
  ├── SilverNFT.sol
  └── VaultEngine.sol
/scripts
  ├── deployEngine.s.sol
  └── helper.s.sol
/test
  └── VaultEngine.t.sol
foundry.toml
README.md
```

---

## ⚙️ Prerequisites

- [Foundry](https://book.getfoundry.sh/) – Smart contract development and testing.
- [Node.js](https://nodejs.org/) – For scripting and dependency management.
- Ethereum testnet RPC (e.g., Sepolia).
- Wallet private key with testnet ETH.

---

## 🧪 Installation

```bash
# Clone the repository
git clone https://github.com/your-repo/silver-tokenization.git
cd silver-tokenization

# Install Node dependencies
npm install

# Install Foundry
npm install -g foundry
```

Configure your RPC and private key inside `foundry.toml`:

```toml
[rpc_endpoints]
sepolia = "https://sepolia.infura.io/v3/YOUR_INFURA_KEY"

[profile.default]
src = "contracts"
out = "out"
libs = ["lib"]
```

---

## 🚀 Deployment

```bash
# Compile smart contracts
forge build

# Deploy to Sepolia
forge script scripts/deployEngine.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

Optional: Verify your contracts on Etherscan.

```bash
forge verify-contract --chain-id 11155111 \
  --contract-name VaultEngine \
  --constructor-args <ARGS> \
  <DEPLOYED_ADDRESS>
```

---

## 💰 Usage Instructions

### ✅ Buying Silver Tokens

```bash
cast send <YOUR_WALLET_ADDRESS> \
  <SILVER_ERC20_CONTRACT_ADDRESS> \
  "buy(uint256)" 100 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

### 🔁 Redeeming Silver Tokens

```bash
cast send <YOUR_WALLET_ADDRESS> \
  <VAULT_ENGINE_CONTRACT_ADDRESS> \
  "redeem(uint256)" 100 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

---

## 🧪 Testing

Run unit tests using Foundry:

```bash
forge test
```

This covers:
- ERC20 mint/burn behavior
- ERC721 metadata correctness
- Redemption atomicity
- Vault bar assignment

---

## 📊 Benchmarking

To analyze gas usage:

```bash
forge snapshot
```

Look at:
- Gas cost per `redeem()`
- Storage size for each ERC721 NFT
- Comparison between chains (if cross-deployed)

---

## 🔒 Access Control & Roles

- `DEFAULT_ADMIN_ROLE`: Deployer or governance account
- `MINTER_ROLE`: Allowed to mint ERC20 (e.g., bridge, backend)
- `BURNER_ROLE`: Allowed to burn ERC20 tokens (used by VaultEngine)
- `REDEMPTION_MANAGER_ROLE`: Controls NFT minting from the `VaultEngine`

---

## 🌐 Optional Oracle Integration

Chainlink Price Feeds can be integrated to dynamically convert fiat to token amount.

```solidity
AggregatorV3Interface internal priceFeed;
```

Settable via constructor or `setOracle()` function (optional).

---

## 🗂 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🧩 Future Improvements

- Vault assignment by geographic proximity.
- zkSync and Solana deployment benchmarks.
- Frontend redemption dashboard.
- Role-based multisig governance.

---

## Let us know if you'd like to contribute or collaborate!
