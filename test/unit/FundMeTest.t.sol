// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
 
contract FundMeTest is Test{
    FundMe fundMe;
    address user = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external{
        DeployFundMe deployFundMe = new DeployFundMe();

        fundMe = deployFundMe.run();

        vm.deal(user, STARTING_BALANCE);
    }

    function testMiniDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public{ 
        assertEq(fundMe.getOwner(), msg.sender );
    }

    function testPriceFeedVersionIsAccurate() public{
        assertEq(fundMe.getVersion(),  4);
    }

    function testFundFailedWithoutEnoughEth() public{
        vm.expectRevert(); //next line hve to be failure
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(user); // the next sender will be user

        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(user);
        assertEq (amountFunded, SEND_VALUE);
        
    }

    function testAddsFunderToArrayOfFunders() public{
        vm.prank(user);
        fundMe.fund{value: SEND_VALUE}();

        assertEq(fundMe.getFunder(0), user);
    }

    modifier funded(){
        vm.prank(user);
        fundMe.fund{value : SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.expectRevert();
        vm.prank(user);

        fundMe.withdraw();
    }

    function testWithdrawAsSingleFunder() public funded{
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, endingOwnerBalance);


    }

    function testWithdrawFromMultipleFunder() public funded{
        uint256 numberOfFunder = 10;
        uint256 startingFunderIndex = 1;

        for (uint256 i = startingFunderIndex; i < numberOfFunder; i++){

            hoax(address(uint160(i)), SEND_VALUE);
            fundMe.fund{value : SEND_VALUE} ();
            
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == 
            fundMe.getOwner().balance
        );

    }

    function testWithdrawFromMultipleFunderCheaper() public funded{
        uint256 numberOfFunder = 10;
        uint256 startingFunderIndex = 1;

        for (uint256 i = startingFunderIndex; i < numberOfFunder; i++){

            hoax(address(uint160(i)), SEND_VALUE);
            fundMe.fund{value : SEND_VALUE} ();
            
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithDraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == 
            fundMe.getOwner().balance
        );

    }
    
}