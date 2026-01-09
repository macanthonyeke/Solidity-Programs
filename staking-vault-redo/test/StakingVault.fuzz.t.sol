// SPDX-Linsense-Identifier MIT
pragma solidity >0.8.18;

import "forge-std/Test.sol";
import "../src/StakingVault.sol";
import "../src/MockToken.sol";

contract StakingVaultFuzzTest is Test {
    StakingVault vault;
    MockToken token;
    address user = address(0x123);

    uint[] public validTimes;

    function setUp() public {
        token = new MockToken();
        vault = new StakingVault(address(token));

        validTimes.push(120);
        validTimes.push(300);
        validTimes.push(420);
        validTimes.push(600);

        token.transfer(address(vault), 500000 ether);
        token.transfer(user, 500000 ether);
    }

    function testFuzz_FullCycle(uint256 amount, uint256 randIndex) public {
        
        vm.assume(amount > 0);
        vm.assume(amount <= 500000 ether);
        
        uint timeIndex = randIndex % validTimes.length;
        uint chosenTime = validTimes[timeIndex]; 
        
        vm.startPrank(user);
        token.approve(address(vault), amount);
        vault.stake(amount, chosenTime);

        vm.warp(block.timestamp + chosenTime + 1);

        vault.unstake(0); 
        
        vm.stopPrank();

        assert(token.balanceOf(user) >= 500000 ether);
    }
}