// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; 

contract DeployRaffle is Script{
    
    uint256 constant ENTRANCE_FEE = 5e14;

    function run() external returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(ENTRANCE_FEE, config.vrfCoordinatorAddress, config.subId, config.keyHash, config.callbackGasLimit);

        // Add raffle as consumer to the vrfCoordinator contract
        VRFCoordinatorV2_5Mock(config.vrfCoordinatorAddress).addConsumer(config.subId, address(raffle));
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}