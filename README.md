# 🚢 Shipping Insurance Swap

> A decentralized platform for swapping shipping insurance contracts automatically on the Stacks blockchain

## 📖 Overview

Shipping Insurance Swap is a smart contract system that enables users to create, manage, and automatically swap shipping insurance contracts. Perfect for logistics companies, freight forwarders, and cargo owners who need flexibility in their insurance coverage.

## ✨ Features

- 📋 **Create Insurance Contracts**: Generate custom insurance policies for shipping cargo
- 🔄 **Automatic Swapping**: Propose and accept insurance contract swaps seamlessly
- 💰 **Escrow System**: Built-in balance management for secure transactions
- ⏰ **Time-bound Proposals**: Set expiry dates for swap proposals
- 🔒 **Access Control**: Only contract owners can manage their policies
- 📊 **Query Functions**: Easy access to contract and swap data

## 🛠️ Installation

### Prerequisites
- [Clarinet](https://docs.hiro.so/clarinet) installed
- [Node.js](https://nodejs.org/) (for testing)

### Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd Shipping-Insurance-Swap

# Install dependencies
npm install

# Run tests
clarinet test
```

## 🚀 Usage

### 1. Creating an Insurance Contract

```clarity
(contract-call? .shipping-insurance-swap create-insurance-contract 
  "Electronics"  ;; cargo-type
  u10000         ;; value in STX
  u500           ;; premium in STX
  "New York"     ;; destination
  u144           ;; duration in blocks (~24 hours)
)
```

### 2. Depositing STX for Swaps

```clarity
(contract-call? .shipping-insurance-swap deposit u1000) ;; Deposit 1000 microSTX
```

### 3. Proposing a Swap

```clarity
(contract-call? .shipping-insurance-swap propose-swap 
  u1    ;; your insurance contract ID
  u2    ;; target insurance contract ID
  u100  ;; additional payment (optional)
  u144  ;; proposal expiry in blocks
)
```

### 4. Accepting a Swap

```clarity
(contract-call? .shipping-insurance-swap accept-swap u1) ;; swap proposal ID
```

### 5. Querying Contract Data

```clarity
;; Get insurance contract details
(contract-call? .shipping-insurance-swap get-insurance-contract u1)

;; Get swap proposal details
(contract-call? .shipping-insurance-swap get-swap-proposal u1)

;; Check user balance
(contract-call? .shipping-insurance-swap get-user-balance tx-sender)
```

## 📊 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|-----------|
| `deposit` | 💰 Deposit STX to contract balance | `amount: uint` |
| `withdraw` | 💸 Withdraw STX from contract balance | `amount: uint` |
| `create-insurance-contract` | 📋 Create new insurance policy | `cargo-type, value, premium, destination, duration-blocks` |
| `propose-swap` | 🔄 Propose insurance contract swap | `my-insurance-id, target-insurance-id, additional-payment, duration-blocks` |
| `accept-swap` | ✅ Accept a swap proposal | `swap-id: uint` |
| `cancel-swap` | ❌ Cancel your swap proposal | `swap-id: uint` |
| `deactivate-insurance` | 🚫 Deactivate your insurance contract | `insurance-id: uint` |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|--------|
| `get-insurance-contract` | 📄 Get insurance contract details | Contract data or none |
| `get-swap-proposal` | 📋 Get swap proposal details | Proposal data or none |
| `get-user-balance` | 💳 Get user's contract balance | Balance in microSTX |
| `get-next-insurance-id` | 🔢 Get next insurance contract ID | Next ID number |
| `get-next-swap-id` | 🔢 Get next swap proposal ID | Next ID number |

## 🔐 Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `ERR-NOT-AUTHORIZED` | User not authorized for this action |
| 101 | `ERR-INSURANCE-NOT-FOUND` | Insurance contract doesn't exist |
| 102 | `ERR-ALREADY-SWAPPED` | Contract already swapped |
| 103 | `ERR-CANNOT-SWAP-OWN` | Cannot swap with your own contract |
| 104 | `ERR-SWAP-NOT-FOUND` | Swap proposal doesn't exist |
| 105 | `ERR-INVALID-AMOUNT` | Invalid amount provided |
| 106 | `ERR-INSUFFICIENT-BALANCE` | Insufficient contract balance |

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Run specific test file
clarinet test tests/shipping-insurance-swap.test.ts

# Check contract syntax
clarinet check
```

## 🏗️ Architecture

The contract uses three main data structures:

1. **📋 Insurance Contracts**: Store policy details, ownership, and status
2. **🔄 Swap Proposals**: Manage swap requests between parties
3. **💰 User Balances**: Track STX deposits for swap payments

## 💡 Use Cases

- **🚛 Logistics Companies**: Swap insurance based on changing routes
- **📦 E-commerce**: Exchange coverage for different product types
- **🌊 Freight Forwarders**: Trade policies for optimal coverage
- **🏭 Manufacturers**: Adjust insurance for seasonal shipping patterns



## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

For questions and support, please open an issue on GitHub.

---

*Built with ❤️ on the Stacks blockchain*
