// SPDX-Lisense-Identifier: MIT
pragma solidity >0.8.18;

import "forge-std/Test.sol";
import "../src/StakingVault.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor () ERC20 ("Fake Token", "FAKE") {
        _mint(msg.sender, 1000000 * 10**18);
    }
}

contract StakingVaultTest is Test {
    StakingVault vault;
    MockToken token;
    address user = address(1);

    function setUp () public {
        token = new MockToken();

        vault = new StakingVault(address(token));

        token.transfer(user, 100 ether);

        token.transfer(address(vault), 1000 ether);
    }

    function testStaking () public {
        vm.startPrank(user);

        token.approve(address(vault), 100 ether);

        vault.stake(100 ether, 120);

        vm.stopPrank;

        assertEq(token.balanceOf(address(vault)), 1100 ether);

        assertEq(token.balanceOf(address(user)), 0);
    }

    function testUnstaking () public {
        vm.startPrank(user);

        token.approve(address(vault), 100 ether);

        vault.stake(100 ether, 120);

        vm.warp(block.timestamp + 200);
        vault.unstake(0);

        assertEq(token.balanceOf(user), 105 ether);
        vm.stopPrank();
    }
}