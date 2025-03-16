// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract SimpleEscrow {
    address payable public buyer;
    address payable public seller;
    uint256 public amount;
    bool public isFunded;
    bool public isReleased;

    event Funded(address buyer, uint256 amount);
    event Released(address seller, uint256 amount);
    event Refunded(address buyer, uint256 amount);

    // Modifier to check if the caller is the buyer
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    //Constructor that sets the buyer and seller addresses
    //Address of the seller who will receive the funds

    constructor(address payable _seller) {
        require(_seller != address(0), "Invalid seller address");
        buyer = payable(msg.sender);
        seller = _seller;
    }

    /**
     * Allows the buyer to fund the escrow
     */
    function fundEscrow() external payable onlyBuyer {
        require(!isFunded, "Escrow already funded");
        require(msg.value > 0, "Amount must be greater than 0");

        amount = msg.value;
        isFunded = true;

        emit Funded(buyer, amount);
    }

    /**
     * Allows the buyer to release funds to the seller
     */
    function releaseFunds() external onlyBuyer {
        require(isFunded, "Escrow not funded");
        require(!isReleased, "Funds already released");

        isReleased = true;

        (bool sent,) = seller.call{value: amount}("");
        require(sent, "Failed to release funds to seller");

        emit Released(seller, amount);
    }

    /**
     * Allows the buyer to get a refund if needed
     *   This function should be used in case of dispute or if the deal is cancelled
     */
    function refund() external onlyBuyer {
        require(isFunded, "Escrow not funded");
        require(!isReleased, "Funds already released");

        isFunded = false;

        (bool sent,) = buyer.call{value: amount}("");
        require(sent, "Failed to refund buyer");

        emit Refunded(buyer, amount);
    }

    /**
     * Get the current balance of the contract
     *   The current balance in wei
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
