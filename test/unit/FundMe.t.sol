// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DepolyFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    address USER = makeAddr("user");
    uint constant SEND_VALUE = 0.1 ether;
    uint constant STARTING_BALANCE = 10 ether;
    uint constant GAS_PRICE = 1;

    function setUp() external{
        //us ->FundeMeTest ->FundMe
     DeployFundMe deployFundMe = new DeployFundMe();
     fundMe = deployFundMe.run();
     vm.deal(USER,STARTING_BALANCE);

    }

    function testMinimumDollorIsFive() view public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);        
    }

    function testOwnerIsMsgSender() view public{
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() view public {
        uint version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        uint amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm. expectRevert();
        fundMe.withdraw();
    }
    
    function testDrawWithASingleFunder() public funded {
        // Arrange Act Assert
        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundmeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint endingOwnerBalance = fundMe.getOwner().balance;
        uint endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundmeBalance+startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberofFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i=startingFunderIndex; i<numberofFunders; i++){
            //vm.prank
            //vm.deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }

        uint startOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalanc = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalanc + startOwnerBalance == fundMe.getOwner().balance);
    } 

}