// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/AnimalNFT.sol";

/// forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
contract Deploy is Script {
    function run() external returns (AnimalNFT nft) {
        vm.startBroadcast();
        nft = new AnimalNFT();
        vm.stopBroadcast();
        console.log("AnimalNFT deployed at", address(nft));
    }
}
