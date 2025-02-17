# 🎟️ Raffle Smart Contract

Welcome to the **Raffle Smart Contract** project! This project implements a simple and fun raffle system using Ethereum smart contracts. Users can enter the raffle by paying a certain amount of Ether, and a random winner is selected to win the entire pot! 🏆

## 📜 Overview

This contract is designed to:
- Allow users to enter the raffle by sending Ether.
- Use Chainlink's VRF (Verifiable Random Function) to randomly select a winner.
- Transfer the total Ether collected to the winner.

## 🚀 Getting Started

### Prerequisites

- Foundry
- Ethereum wallet (e.g., MetaMask)
- Test Ether (for testing on testnets)

### Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/yourusername/lottery-smart-contract.git
    cd lottery-smart-contract
    ```

2. Install Foundry:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

### Deployment

1. Compile the smart contract:
    ```bash
    forge build
    ```

2. Deploy the contract to a testnet (e.g., Rinkeby):
    ```bash
    forge create --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> src/Raffle.sol:Raffle --constructor-args <VRF_COORDINATOR> <LINK_TOKEN> <KEY_HASH> <FEE>
    ```

## 📖 Usage

1. Enter the raffle by sending Ether to the contract.
2. The contract owner can call the `pickWinner` function to select a random winner.
3. The winner receives the total Ether collected.

## 📄 License

This project is licensed under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## 📧 Contact

For any inquiries, please contact [biswjitdebnath405@gmail.com].

Happy raffling! 🎉
