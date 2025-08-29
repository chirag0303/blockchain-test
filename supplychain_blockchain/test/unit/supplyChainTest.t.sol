// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DeploySupplyChain} from "../../script/DeploySupplyChain.s.sol";
import {SupplyChain} from "../../src/supplyChain.sol";

contract supplyChainTest is Test{

    SupplyChain public supplyChain;
    uint256 shipmentId;
    address Updater_add_anvil = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address Admin_add_anvil = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() external {
        DeploySupplyChain deployer = new DeploySupplyChain();
        (supplyChain,shipmentId) = deployer.deployContract();
        
    }

    function testShipmentCreated() public {
        //Arrange
        vm.prank(Updater_add_anvil);

        //Act
        uint256 id = supplyChain.createShipment("Shipment1");
        //console.log(id);

        //Assert
        assert(supplyChain.getShipment(id).status == SupplyChain.Status.Created);
        //This ensures a shipment is created.
    }

    function testStatusUpdated() public {
        //Arrange
        vm.prank(Updater_add_anvil);

        //Act
        supplyChain.updateStatus(shipmentId, SupplyChain.Status.InTransit, "Updating Shipment");

        //Assert
        assert(supplyChain.getShipment(shipmentId).status == SupplyChain.Status.InTransit);
        // This ensure status has been updated
    }

    function testRoleAssignment() public {
        //Arrange
        vm.prank(Admin_add_anvil);

        // Act/assert
        vm.expectRevert();
        supplyChain.updateStatus(shipmentId, SupplyChain.Status.InTransit, "Updating Shipment");
        // This will revert as updateStatus can only be called by updater not the admin or any other.
    }
}