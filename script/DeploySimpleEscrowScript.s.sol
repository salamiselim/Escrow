 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {SimpleEscrow} from "../src/SimpleEscrow.sol";

contract DeployEscrow is Script {
    function run() external {
        // Using anvil's default private key
       
        
        // Using anvil's second account as seller
        address payable sellerAddress = payable(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        
        // Start broadcasting transactions
        vm.startBroadcast(); //deployerPrivateKey
        
        // Deploy the escrow contract
        SimpleEscrow escrow = new SimpleEscrow(sellerAddress);
        
        // End broadcasting
        vm.stopBroadcast();
        
        // Log the contract address
        console.log("Escrow contract deployed at: ", address(escrow));
        console.log("Buyer (deployer): ", escrow.buyer());
        console.log("Seller: ", escrow.seller());
    }
}
       