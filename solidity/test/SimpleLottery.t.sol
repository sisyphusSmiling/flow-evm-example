// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleLottery} from "../src/SimpleLottery.sol";

contract Test is Test {
    SimpleLottery public SimpleLottery;

    function setUp() public {
        lottery = new SimpleLottery();
    }

    function test_PurchaseTicket() public {
        lottery.purchaseTickets(1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
