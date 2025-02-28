// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

/**
 * @title HelperConfigTest
 * @dev This contract contains unit tests for the HelperConfig contract, which provides network-specific configurations for the Lottery Smart Contract.
 *
 * The tests cover the following scenarios:
 * - Retrieving Sepolia network configuration.
 * - Retrieving local Anvil network configuration.
 * - Retrieving configuration by chain ID.
 * - Verifying VRF coordinator deployment in local configuration.
 * - Testing the caching mechanism for local configuration.
 * - Validating code constants defined in the HelperConfig contract.
 * - Handling unsupported chain IDs gracefully.
 *
 * Constants:
 * - ENTRANCE_FEE: The entrance fee for the lottery.
 * - SEPOLIA_CHAIN_ID: The chain ID for the Sepolia network.
 * - LOCAL_CHAIN_ID: The chain ID for the local Anvil network.
 *
 * Dependencies:
 * - DeployRaffle: A contract used to deploy the Raffle contract.
 * - HelperConfig: A contract that provides network-specific configurations.
 * - VRFCoordinatorV2_5Mock: A mock contract for the VRF Coordinator.
 *
 * The tests use the Forge testing framework and the vm cheat codes for mocking chain IDs.
 */
contract HelperConfigTest is Test {
    DeployRaffle deployer;
    HelperConfig helperConfig;

    // Constants used in the scripts
    uint256 constant ENTRANCE_FEE = 5e14;
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    function setUp() external {
        deployer = new DeployRaffle();
    }

    function testGetSepoliaNetworkConfig() public {
        // Create a new HelperConfig
        helperConfig = new HelperConfig();

        // Mock the chain ID to Sepolia
        vm.chainId(SEPOLIA_CHAIN_ID);

        // Get the config for the mocked chain ID
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Validate Sepolia configuration
        assertEq(
            config.vrfCoordinatorAddress,
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            "Incorrect VRF coordinator address for Sepolia"
        );
        assertEq(
            config.keyHash,
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
            "Incorrect key hash for Sepolia"
        );
        assertEq(config.callbackGasLimit, 500000, "Incorrect callback gas limit for Sepolia");
    }

    function testGetLocalAnvilNetworkConfig() public {
        // Create a new HelperConfig
        helperConfig = new HelperConfig();

        // Mock the chain ID to local Anvil chain
        vm.chainId(LOCAL_CHAIN_ID);

        // Get the config for the mocked chain ID
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Validate local configuration
        assertTrue(config.vrfCoordinatorAddress != address(0), "VRF coordinator address not set for local chain");
        assertTrue(config.subId > 0, "Subscription ID not set for local chain");
        assertEq(
            config.keyHash,
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            "Incorrect key hash for local chain"
        );
        assertEq(config.callbackGasLimit, 500000, "Incorrect callback gas limit for local chain");
    }

    function testGetConfigByChainId() public {
        // Create a new HelperConfig
        helperConfig = new HelperConfig();

        // Test for Sepolia chain ID
        HelperConfig.NetworkConfig memory sepoliaConfig = helperConfig.getConfigByChainId(SEPOLIA_CHAIN_ID);
        assertEq(
            sepoliaConfig.vrfCoordinatorAddress,
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
            "Incorrect VRF coordinator address for Sepolia"
        );

        // Test for local Anvil chain ID
        HelperConfig.NetworkConfig memory localConfig = helperConfig.getConfigByChainId(LOCAL_CHAIN_ID);
        assertTrue(localConfig.vrfCoordinatorAddress != address(0), "VRF coordinator address not set for local chain");
    }

    function testVrfCoordinatorDeploymentInLocalConfig() public {
        // Create a new HelperConfig
        helperConfig = new HelperConfig();

        // Mock the chain ID to local Anvil chain
        vm.chainId(LOCAL_CHAIN_ID);

        // Get the config for the local chain
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Verify the VRF coordinator is properly deployed
        VRFCoordinatorV2_5Mock vrfCoordinator = VRFCoordinatorV2_5Mock(config.vrfCoordinatorAddress);

        // Check if the subscription exists
        (uint96 balance,,,,) = vrfCoordinator.getSubscription(config.subId);

        // Check if subscription is funded
        assertGt(balance, 0, "Subscription not funded");
    }

    function testLocalConfigCaching() public {
        // Create a new HelperConfig
        helperConfig = new HelperConfig();

        // Mock the chain ID to local Anvil chain
        vm.chainId(LOCAL_CHAIN_ID);

        // Get the config twice
        HelperConfig.NetworkConfig memory config1 = helperConfig.getConfig();
        HelperConfig.NetworkConfig memory config2 = helperConfig.getConfig();

        // Both configurations should have the same VRF coordinator address
        assertEq(config1.vrfCoordinatorAddress, config2.vrfCoordinatorAddress, "Cache mechanism not working properly");
        assertEq(config1.subId, config2.subId, "Subscription IDs don't match, indicating multiple creations");
    }

    function testCodeConstants() public {
        // Create a new HelperConfig
        helperConfig = new HelperConfig();

        // Access the constants from the contract
        assertEq(helperConfig.MOCK_BASE_FEE(), 25e16, "Incorrect MOCK_BASE_FEE");
        assertEq(helperConfig.MOCK_GAS_PRICE_LINK(), 1e9, "Incorrect MOCK_GAS_PRICE_LINK");
        assertEq(helperConfig.MOCK_WEI_PER_UINT_LINK(), 4e17, "Incorrect MOCK_WEI_PER_UINT_LINK");
    }

    function testUnsupportedChainIdFallback() public {
        // Create a new HelperConfig
        helperConfig = new HelperConfig();

        // Test with an unsupported chain ID (e.g., Mainnet = 1)
        vm.chainId(1);

        // Since Mainnet isn't supported, it should return an empty config
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Expected behavior is to return an empty/default config for unsupported chains
        assertEq(config.vrfCoordinatorAddress, address(0), "Unsupported chain should return default config");
        assertEq(config.subId, 0, "Unsupported chain should return default config");
    }
}
