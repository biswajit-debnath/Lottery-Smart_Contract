# 🚀 Deployment Guide

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation.html) installed
- [Chainlink VRF Subscription](https://vrf.chain.link/) created
- Test ETH for deployment

## Environment Setup 🔧

1. Create a `.env` file:

```bash
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
VRF_SUBSCRIPTION_ID=your_vrf_subscription_id
```

2. Load environment variables:

```bash
source .env
```

## Deployment Steps 📝

1. **Compile Contracts**

```bash
forge build
```

2. **Deploy to Testnet (Sepolia)**

```bash
forge script script/DeployRaffle.s.sol:DeployRaffle \
--rpc-url $SEPOLIA_RPC_URL \
--private-key $PRIVATE_KEY \
--broadcast \
--verify
```

3. **Verify Contract Parameters**
```solidity
// Check deployment
cast call $RAFFLE_ADDRESS "getEntranceFeeAmountInEth()" --rpc-url $SEPOLIA_RPC_URL
cast call $RAFFLE_ADDRESS "getSubscriptionId()" --rpc-url $SEPOLIA_RPC_URL
```

## Post-Deployment Setup ⚙️

1. Fund VRF Subscription with LINK tokens
2. Add deployed contract as VRF consumer
3. Verify contract on Etherscan

## Configuration Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| entranceFee | 0.0005 ETH | Minimum entry amount |
| callbackGasLimit | 500000 | Gas limit for VRF callback |
| keyHash | 0x...| VRF key hash for network |

## Deployment Verification ✅

1. Check contract is verified on Etherscan
2. Test basic functions:
   - Enter raffle
   - Check participant list
   - Verify VRF integration