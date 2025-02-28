# 🧪 Testing Guide

## Test Structure 📋

```
tests/
├── unit/
    └── RaffleTest.t.sol
```

## Running Tests 🏃‍♂️

### All Tests

```bash
forge test
```

### Specific Tests

```bash
forge test --match-test testEnterRaffle
```

### With Verbosity

```bash
forge test -vvv
```

## Test Coverage 📊

```bash
forge coverage
```

## Unit Tests 🔬

### Core Functionality Tests

```solidity
function testEnterRaffle() public
function testRunLottery() public
function testPickWinner() public
```

### Error Cases

```solidity
function testFailInsufficientEntrance() public
function testRevertWhenRaffleNotOpen() public
function testFailInvalidVRFResponse() public
```

## Integration Tests 🔗

### Full Cycle Test

```solidity
function testFullRaffleCycle() public
```

### Multiple Participants Test

```solidity
function testMultipleParticipants() public
```

## Gas Reporting ⛽

```bash
forge test --gas-report
```

## Test Fixtures 🛠️

```solidity
function setUp() public {
    // Common test setup
}
```


## Mock Contracts 🎭

- MockVRFCoordinator
