// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock";

abstract contract CodeConstants {
    uint96 public MOCK_BASE_FEE = 0.25 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
}

contract HelperConfig is CodeConstants, Script {


    struct NetworkConfig {
        address vrfCoordinatorAddress
    }


    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    mapping(uint256 => NetworkConfig) chainIdToNetworkConfig;
    NetworkConfig localChainNetworkConfig;


    constructor() {
        chainIdToNetworkConfig[SEPOLIA_CHAIN_ID] = getSepoliaNetworkConfig();
    } 
    
    function getConfig() returns(memory NetworkConfig) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) returns(memory NetworkConfig){
        if(chainId != LOCAL_CHAIN_ID) {
            return chainIdToNetworkConfig[chainId];
        } else {
            return getLocalAnvilNetworkConfig();
        }
    }


    // Function to get networkConfig for sepolia
    function getSepoliaNetworkConfig() internal pure returns(memory NetworkConfig) {
        return NetworkConfig({
            vrfCoordinatorAddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
        });
    }

    // Funtion to get networkConfig for local anvil chain
    function getLocalAnvilNetworkConfig() internal returns(memory NetworkConfig) {


        // Deploy a mock vrf coordinator
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);

        // Create subscription
        uint64 subId = VRFCoordinatorV2_5Mock.createSubscription();

        // Fund the subscription
        VRFCoordinatorV2_5Mock.fundSubscription(subId, 1 ether);
        
        vm.stopBroadcast();


        // Return the vrfCoordinator address
        localChainNetworkConfig = NetworkConfig({
            vrfCoordinator: address(VRFCoordinatorV2_5Mock)
        })

        return localChainNetworkConfig;
    }

}