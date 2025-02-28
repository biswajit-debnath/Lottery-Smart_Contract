// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; 

/**
 * @title CodeConstants
 * @dev This abstract contract defines constants used for mocking and configuration purposes in the Lottery Smart Contract project.
 * 
 * @notice The constants defined in this contract include:
 * - MOCK_BASE_FEE: A mock base fee used for testing purposes.
 * - MOCK_GAS_PRICE_LINK: A mock gas price for LINK tokens used for testing purposes.
 * - MOCK_WEI_PER_UINT_LINK: A mock price of LINK in terms of WEI used for testing purposes.
 * - SEPOLIA_CHAIN_ID: The chain ID for the Sepolia test network.
 * - LOCAL_CHAIN_ID: The chain ID for the local development network.
 * 
 * These constants are intended to be used in scripts and tests to simulate various blockchain conditions.
 */
abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 25e16;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e17;

    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
}





/**
 * @title HelperConfig
 * @dev This contract provides network configuration details for different blockchain networks.
 * It includes configurations for the Sepolia test network and a local Anvil network.
 * The contract allows retrieval of network configurations based on the current chain ID or a specified chain ID.
 * It also handles the deployment and funding of a mock VRFCoordinator for the local Anvil network.
 */
contract HelperConfig is CodeConstants, Script {

    struct NetworkConfig {
        address vrfCoordinatorAddress;
        uint256 subId;
        bytes32 keyHash; 
        uint32 callbackGasLimit;
    }

    
    mapping(uint256 => NetworkConfig) chainIdToNetworkConfig;
    NetworkConfig localChainNetworkConfig;


    constructor() {
        chainIdToNetworkConfig[SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
    } 
    
    /**
     * @notice Retrieves the network configuration for the current blockchain network.
     * @dev This function calls `getConfigByChainId` with the current chain ID obtained from `block.chainid`.
     * @return NetworkConfig The network configuration for the current blockchain network.
     */
    function getConfig() external returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    /**
     * @notice Retrieves the network configuration based on the provided chain ID.
     * @dev If the chain ID matches the local chain ID, it returns the local Anvil network configuration.
     * @param chainId The ID of the blockchain network.
     * @return NetworkConfig The network configuration corresponding to the provided chain ID.
     */
    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(chainId != LOCAL_CHAIN_ID) {
            return chainIdToNetworkConfig[chainId];
        } else {
            return getLocalAnvilNetworkConfig();
        }
    }


    
    /**
     * @notice Returns the network configuration for the Sepolia test network.
     * @dev This function provides the necessary configuration details for interacting with the Sepolia network.
     * @return NetworkConfig memory containing the VRF Coordinator address, subscription ID, key hash, and callback gas limit.
     */
    function getSepoliaNetworkConfig() internal pure returns(NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorAddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subId: 18541826859728935111278688522415752663091092770622187897088624603391258799582,
            keyHash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            callbackGasLimit: 500000
        });
    }

    
    /**
     * @notice Retrieves the local Anvil network configuration.
     * @dev If the localChainNetworkConfig has a non-zero vrfCoordinatorAddress, it returns the existing configuration.
     *      Otherwise, it deploys a mock VRFCoordinatorV2_5, creates and funds a subscription, and updates the localChainNetworkConfig.
     * @return NetworkConfig The configuration for the local Anvil network.
     */
    function getLocalAnvilNetworkConfig() internal returns(NetworkConfig memory) {

        if(localChainNetworkConfig.vrfCoordinatorAddress != address(0)) {
            return localChainNetworkConfig;
        }
    
        // Deploy a mock vrf coordinator
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        
        // Create subscription
        uint256 subId = vrfCoordinator.createSubscription();

        // Fund the subscription
        vrfCoordinator.fundSubscription(subId, 1 ether);
        
        vm.stopBroadcast();


        // Return the vrfCoordinator address
        localChainNetworkConfig = NetworkConfig({
            vrfCoordinatorAddress: address(vrfCoordinator),
            subId: subId,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000
        });

        return localChainNetworkConfig;
    }

}