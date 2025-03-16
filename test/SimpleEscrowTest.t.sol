// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {SimpleEscrow} from "../src/SimpleEscrow.sol";

contract SimpleEscrowTest is Test {
    SimpleEscrow escrow;
    address payable buyer;
    address payable seller;
    uint256 initialAmount = 1 ether;

    function setUp() public {
        // Set up buyer and seller addresses
        buyer = payable(address(0x1));
        seller = payable(address(0x2));
        
        // Give buyer some ETH
        vm.deal(buyer, 10 ether);
        
        // Deploy the escrow contract as buyer
        vm.prank(buyer);
        escrow = new SimpleEscrow(seller);
    }
    
    function test_InitialState() public view {
        assertEq(escrow.buyer(), buyer);
        assertEq(escrow.seller(), seller);
        assertEq(escrow.amount(), 0);
        assertEq(escrow.isFunded(), false);
        assertEq(escrow.isReleased(), false);
    }
    
    function test_FundEscrow() public {
        // Fund escrow as buyer
        vm.prank(buyer);
        escrow.fundEscrow{value: initialAmount}();
        
        // Verify state after funding
        assertEq(escrow.amount(), initialAmount);
        assertEq(escrow.isFunded(), true);
        assertEq(escrow.isReleased(), false);
        assertEq(address(escrow).balance, initialAmount);
    }
    
    function test_ReleaseFunds() public {
        // Fund escrow first
        vm.prank(buyer);
        escrow.fundEscrow{value: initialAmount}();
        
        // Record seller's balance before release
        uint256 sellerBalanceBefore = seller.balance;
        
        // Release funds to seller
        vm.prank(buyer);
        escrow.releaseFunds();
        
        // Verify seller received the funds
        assertEq(seller.balance, sellerBalanceBefore + initialAmount);
        assertEq(address(escrow).balance, 0);
        assertEq(escrow.isReleased(), true);
    }
    
    function test_Refund() public {
        // Fund escrow first
        vm.prank(buyer);
        escrow.fundEscrow{value: initialAmount}();
        
        // Record buyer's balance before refund
        uint256 buyerBalanceBefore = buyer.balance;
        
        // Request refund
        vm.prank(buyer);
        escrow.refund();
        
        // Verify buyer received the refund
        assertEq(buyer.balance, buyerBalanceBefore + initialAmount);
        assertEq(address(escrow).balance, 0);
        assertEq(escrow.isFunded(), false);
    }
    
    function test_RevertWhen_NonBuyerFunds() public {
    address nonBuyer = address(0x3);
    
    // Give some ETH to the non-buyer
    vm.deal(nonBuyer, 1 ether);
    
    // Set up the prank before expectRevert
    vm.startPrank(nonBuyer);
    
    // Expect the revert
    vm.expectRevert("Only buyer can call this function");
    
    // Make the call that should revert
    escrow.fundEscrow{value: initialAmount}();
    
    vm.stopPrank();
}
    function test_RevertWhen_NonBuyerReleases() public {
        // Fund escrow first
        vm.prank(buyer);
        escrow.fundEscrow{value: initialAmount}();
        
        // Try to release as non-buyer (should revert)
        vm.prank(address(0x3));
        vm.expectRevert("Only buyer can call this function");
        escrow.releaseFunds();
    }
    
    function test_RevertWhen_DoubleRelease() public {
        // Fund escrow
        vm.prank(buyer);
        escrow.fundEscrow{value: initialAmount}();
        
        // Release funds first time
        vm.prank(buyer);
        escrow.releaseFunds();
        
        // Try to release again (should revert)
        vm.prank(buyer);
        vm.expectRevert("Funds already released");
        escrow.releaseFunds();
    }
    
    function test_RevertWhen_ReleaseWithoutFunding() public {
        // Try to release without funding (should revert)
        vm.prank(buyer);
        vm.expectRevert("Escrow not funded");
        escrow.releaseFunds();
    }
    
    function test_RevertWhen_RefundAfterRelease() public {
        // Fund escrow
        vm.prank(buyer);
        escrow.fundEscrow{value: initialAmount}();
        
        // Release funds
        vm.prank(buyer);
        escrow.releaseFunds();
        
        // Try to refund after release (should revert)
        vm.prank(buyer);
        vm.expectRevert("Funds already released");
        escrow.refund();
    }
    
    function test_GetBalance() public {
        // Initially balance should be zero
        assertEq(escrow.getBalance(), 0);
        
        // Fund escrow
        vm.prank(buyer);
        escrow.fundEscrow{value: initialAmount}();
        
        // Verify balance
        assertEq(escrow.getBalance(), initialAmount);
    }
}