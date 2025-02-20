// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script{
    
    uint256 constant ENTRANCE_FEE = 5e14;

    function run() external returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        Raffle raffle = new Raffle(ENTRANCE_FEE, config.vrfCoordinatorAddress, config.subId, config.keyHash, config.callbackGasLimit);

        // Add raffle as consumer to the vrfCoordinator contract
        vm.startBroadcast();
        config.vrfCoordinator.addConsumer(address(raffle));
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}