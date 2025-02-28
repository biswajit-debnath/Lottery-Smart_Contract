// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol"; 

/**
 * @title DeployRaffleTest
 * @dev This contract contains unit tests for the deployment of the Raffle contract using the DeployRaffle script.
 * It verifies the correct deployment and configuration of the Raffle and HelperConfig contracts.
 * The tests include checking the entrance fee, raffle state, subscription ID, and VRF consumer addition.
 */
contract DeployRaffleTest is Test {
    DeployRaffle deployer;
    HelperConfig helperConfig;
    
    // Constants used in the scripts
    uint256 constant ENTRANCE_FEE = 5e14;
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    
    function setUp() external {
        deployer = new DeployRaffle();
    }
    

    function testDeployRaffleScript() public {
        // Run the deploy script
        (Raffle raffle, HelperConfig configHelper) = deployer.run();
        
        // Validate that contracts were deployed
        assertTrue(address(raffle) != address(0), "Raffle contract not deployed");
        assertTrue(address(configHelper) != address(0), "HelperConfig contract not deployed");
        
        // Check if the entrance fee matches the expected value
        assertEq(raffle.getEntranceFeeAmountInEth(), ENTRANCE_FEE, "Entrance fee incorrectly set");
        
        // Verify the raffle state is open (0 = OPEN)
        assertEq(raffle.getCurrentStateOfRaffle(), 0, "Raffle not in OPEN state after deployment");
        
        // Verify the raffle contract has correct subscription ID
        HelperConfig.NetworkConfig memory config = configHelper.getConfig();
        assertEq(raffle.getSubscriptionId(), config.subId, "Subscription ID mismatch");
    }
    
    function testAddConsumerInDeployRaffle() public {
        // Run the deploy script
        (Raffle raffle, HelperConfig configHelper) = deployer.run();
        
        // Get network config to access VRF coordinator
        HelperConfig.NetworkConfig memory config = configHelper.getConfig();
        
        // Check if raffle contract is added as a consumer
        if (block.chainid == LOCAL_CHAIN_ID) {
            VRFCoordinatorV2_5Mock vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinatorAddress);
            (,,,,address[] memory consumers) = vrfCoordinator.getSubscription(config.subId);
            
            bool isConsumer = false;
            for (uint i = 0; i < consumers.length; i++) {
                if (consumers[i] == address(raffle)) {
                    isConsumer = true;
                    break;
                }
            }
            
            assertTrue(isConsumer, "Raffle not added as VRF consumer");
        }
    }
    
}