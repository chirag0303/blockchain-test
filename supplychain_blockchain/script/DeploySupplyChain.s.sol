// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {SupplyChain} from "src/supplyChain.sol";

contract DeploySupplyChain is Script {

    function run() public{
        deployContract();
    }

    function deployContract() public returns (SupplyChain, uint256){
        address admin = vm.envAddress("Admin_add");
        address updater = vm.envAddress("Updater_add");


        
        vm.startBroadcast(vm.envUint("ADMIN_KEY"));
        SupplyChain sc = new SupplyChain(admin);
        //console2.log("Deployed at:", address(sc));

        // Admin grants updater role
        sc.grantUpdater(updater);
        vm.stopBroadcast();

        // Switch to updater for shipment ops
        vm.startBroadcast(vm.envUint("Updater_key"));
        uint256 id = sc.createShipment("Test shipment");
        vm.stopBroadcast();

        return (sc,id);
    }

}