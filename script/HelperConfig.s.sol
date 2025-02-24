// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; 

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 25e16;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
}

contract HelperConfig is CodeConstants, Script {


    struct NetworkConfig {
        address vrfCoordinatorAddress;
        uint256 subId;
        bytes32 keyHash; 
        uint32 callbackGasLimit;
    }


    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    mapping(uint256 => NetworkConfig) chainIdToNetworkConfig;
    NetworkConfig localChainNetworkConfig;


    constructor() {
        chainIdToNetworkConfig[SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
    } 
    
    function getConfig() external returns(NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory){
        if(chainId != LOCAL_CHAIN_ID) {
            return chainIdToNetworkConfig[chainId];
        } else {
            return getLocalAnvilNetworkConfig();
        }
    }


    // Function to get networkConfig for sepolia
    function getSepoliaNetworkConfig() internal pure returns(NetworkConfig memory) {
        return NetworkConfig({
            vrfCoordinatorAddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            subId: 0,
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000
        });
    }

    // Funtion to get networkConfig for local anvil chain
    function getLocalAnvilNetworkConfig() internal returns(NetworkConfig memory) {

        
        vm.roll(100);
        // Deploy a mock vrf coordinator
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinator = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        console.log("block number::::", block.number);
        
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