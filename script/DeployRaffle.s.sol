// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {CodeConstants} from "./HelperConfig.s.sol";

/**
 * @title DeployRaffle
 * @dev This contract is responsible for deploying the Raffle contract with the necessary configurations.
 * It inherits from CodeConstants and Script.
 * The contract sets a constant entrance fee and uses the HelperConfig contract to get network-specific configurations.
 * It then broadcasts the deployment transaction and, if on a local chain, adds the Raffle contract as a consumer to the VRFCoordinator contract.
 */
contract DeployRaffle is CodeConstants, Script {
    uint256 constant ENTRANCE_FEE = 5e14;

    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast();
        Raffle raffle = new Raffle(
            ENTRANCE_FEE, config.vrfCoordinatorAddress, config.subId, config.keyHash, config.callbackGasLimit
        );

        // Add raffle as consumer to the vrfCoordinator contract
        if (block.chainid == LOCAL_CHAIN_ID) {
            // Only add consumer if not on Anvil (local) chain
            VRFCoordinatorV2_5Mock(config.vrfCoordinatorAddress).addConsumer(config.subId, address(raffle));
        }
        vm.stopBroadcast();

        return (raffle, helperConfig);
    }
}
