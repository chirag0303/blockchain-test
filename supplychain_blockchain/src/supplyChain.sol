// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SupplyChain is AccessControl, ReentrancyGuard {
    // --- Roles ---
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    // --- Types ---
    enum Status { Created, InTransit, Delivered }

    struct Shipment {
        uint256 id;
        address creator;
        Status status;
        uint64 createdAt;
        string metadata;
        bool exists;
    }

    struct StatusRecord {
        Status status;
        uint64 timestamp;
        address updater;
        string note;
    }

    // --- Storage ---
    uint256 private _nextId = 1;
    mapping(uint256 => Shipment) private _shipments;
    mapping(uint256 => StatusRecord[]) private _history;

    // --- Events ---
    event ShipmentCreated(uint256 indexed shipmentId, address indexed creator, string metadata);
    event ShipmentStatusUpdated(uint256 indexed shipmentId, Status prev, Status next, address updater, string note);
    event RoleChanged(bytes32 indexed role, address indexed account, address indexed admin, bool granted);

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // Role Management 
    function grantUpdater(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(UPDATER_ROLE, account);
        emit RoleChanged(UPDATER_ROLE, account, msg.sender, true);
    }

    function revokeUpdater(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(UPDATER_ROLE, account);
        emit RoleChanged(UPDATER_ROLE, account, msg.sender, false);
    }

    // Shipment Creation
    function createShipment(string calldata metadata)
        external
        nonReentrant
        onlyRole(UPDATER_ROLE)
        returns (uint256 shipmentId)
    {
        shipmentId = _nextId++;
        Shipment storage s = _shipments[shipmentId];
        s.id = shipmentId;
        s.creator = msg.sender;
        s.status = Status.Created;
        s.createdAt = uint64(block.timestamp);
        s.metadata = metadata;
        s.exists = true;

        _history[shipmentId].push(StatusRecord(Status.Created, uint64(block.timestamp), msg.sender, "Created"));

        emit ShipmentCreated(shipmentId, msg.sender, metadata);
        emit ShipmentStatusUpdated(shipmentId, Status.Created, Status.Created, msg.sender, "Created");
    }

    //Function for updating status of a shipment
    function updateStatus(uint256 shipmentId, Status newStatus, string calldata note)
        external
        nonReentrant
        onlyRole(UPDATER_ROLE)
    {
        Shipment storage s = _shipments[shipmentId];
        require(s.exists, "Shipment !exist");
        Status prev = s.status;
        require(uint8(newStatus) > uint8(prev), "Status can't be same");

        s.status = newStatus;
        _history[shipmentId].push(StatusRecord(newStatus, uint64(block.timestamp), msg.sender, note));

        emit ShipmentStatusUpdated(shipmentId, prev, newStatus, msg.sender, note);
    }

    // getter functions called by anyone
    function getShipment(uint256 shipmentId) external view returns (Shipment memory) {
        require(_shipments[shipmentId].exists, "Shipment !exist");
        return _shipments[shipmentId];
    }

    function getStatusHistory(uint256 shipmentId) external view returns (StatusRecord[] memory) {
        require(_shipments[shipmentId].exists, "Shipment !exist");
        return _history[shipmentId];
    }

    function getUserRoles(address user) external view returns (bool isAdmin, bool isUpdater) {
        isAdmin = hasRole(DEFAULT_ADMIN_ROLE, user);
        isUpdater = hasRole(UPDATER_ROLE, user);
    }

}