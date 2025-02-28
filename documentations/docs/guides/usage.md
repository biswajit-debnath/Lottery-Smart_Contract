# 🎮 Raffle Smart Contract Usage Guide

## Getting Started 🚀

### Prerequisites
- MetaMask or similar Web3 wallet
- Some test ETH (for Sepolia testnet)
- Basic understanding of blockchain transactions

## Participant Guide 👥

### 1. Entering the Raffle

```solidity
// Check entrance fee first
uint256 fee = raffle.getEntranceFeeAmountInEth();

// Enter the raffle
raffle.enterRaffle{value: entranceFee}();
```

### 2. Monitoring Your Entry

```solidity
// Check your investment
uint256 myInvestment = raffle.getAmountInvestedByUser(address);

// View all participants
address[] participants = raffle.getAllCurrentPerticipantsOfLottery();
```

### 3. Checking Results

```solidity
// Get latest winner
address winner = raffle.getLastWinner();

// Check prize amount
uint256 prize = raffle.getLastWinnersPrizeAmount();
```

## Operator Guide 🔧

### 1. Running the Lottery

```solidity
// Start lottery drawing
uint256 requestId = raffle.runLottery();
```

### 2. Monitoring State

```solidity
// Check current state
RaffleState state = raffle.getCurrentStateOfRaffle();
```

## Error Handling 🚨

Common errors and solutions:
- `Raffle__NotEnoughEtherToEnterRaffle`: Increase entry amount
- `Raffle__RaffleNotOpen`: Wait for next round
- `Raffle__Not_Ready_To_Start`: Ensure minimum participants