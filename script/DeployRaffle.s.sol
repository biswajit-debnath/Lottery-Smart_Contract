// SPDX-License-Indentifier: MIT

pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.sol";

contract DeployRaffle is Script{
    
    uint256 constant ENTRANCE_FEE = 5 e14;

    function run() external returns(memory Raffle, memory HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig config = helperConfig.getConfig();

        Raffle raffle = new Raffle(ENTRANCE_FEE, config);

        // Add raffle as consumer to the vrfCoordinator contract
        vm.startBroadcast();
        config.vrfCoordinator.addConsumer(address(raffle));
        vm.stopBroadcast();

        return (raffle, helperConfig)
    }
}