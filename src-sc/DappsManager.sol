// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

import { DappRank } from "./DRNK.sol";
import { AccessControl } from "openzeppelin-contracts/contracts/access/AccessControl.sol";

    // ToDo
    // [x] list fans
    // [x] list dapps
    // [x] airdrop actors demo
    // [x] mint and add fans
    // [x] registerDapp (payable)
    // [x] updateDappCID
    // [x] removeDapp
    // [x] approveDapp
    // [ ] burn tokens
    // [x] banDapp
    // [x] expiredDapp
    // [ ] voteDapp
    // [ ] distributeDRNK
    // For sprint 3 increment the deflation of ultrasound Model.
    // [ ] transfer condition and expiration
    // [ ] IisAlive
    // [ ] sacrifice

contract DappssManager is AccessControl {
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    DappRank public drnk;

    error CallerNotAdmin(address caller);
    error CallerNotDAO(address caller);

    // airdrops
    uint256 public bonus;
    // fee
    uint256 public fee;

    enum Status {
        Submitted,
        Active,
        Expired,
        Banned
    }

    struct Dapp {
        string cid;
        uint256 fans_score;
        uint256 decentralized_score;
        uint256 total_burned;
        address owner;
        Status status;
    }

    struct Fan {
        uint256 multiplier;
        uint256 expires;
    }

    bytes32[] dapps;
    address[] fans;

    mapping (bytes32 => Dapp) dappsIndex;
    mapping (address => Fan) fansIndex;

    constructor(uint _fee, uint _bonus) {
        drnk = new DappRank(msg.sender, msg.sender);
        fee = _fee;
        bonus = _bonus;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // to be updated with an address as the admin role
        _grantRole(DAO_ROLE, msg.sender);
    }

    function demoAirdrop(address[] calldata actors) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert CallerNotAdmin(msg.sender);
        }

        for(uint i; i <= actors.length; i++) {
            _mint(actors[i], bonus);
        }
    }

    function _mint(address to, uint256 amount) private {
        require(msg.sender == address(this));
        if(fanExists(to)) {
            drnk.mint(to, amount);
            fansIndex[to].expires = block.timestamp + 4 weeks;
        } else {
            fans.push(to);
            drnk.mint(to, amount);
            fansIndex[to] = Fan(bonus, block.timestamp + 4 weeks);
        }
    }

    function registerDapp(
        bytes32 name,
        string memory cid
    ) public payable {
        require(msg.value >= fee, "Error: listing fee uncovered");
        require(!DappNameExists(name));
        dappsIndex[name]= Dapp(
            cid,
            0,
            0,
            0,
            msg.sender,
            Status.Submitted
        );
        dapps.push(name);
        _mint(msg.sender, 10 * bonus);
    }

    function approveDapp(bytes32 name) external {
        require(DappNameExists(name));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender));
        dappsIndex[name].status = Status.Active;
    }

    function banDapp(bytes32 name) external {
        require(DappNameExists(name));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender));
        dappsIndex[name].status = Status.Banned;
    }

    //function expiredDapp(bytes32 name) external {
    //    require(DappNameExists(name));
    //    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender));
    //    // ToDo: require(many epoach of none votes))
    //    dappsIndex[name].status = Status.Expired;
    //}

    function updateDappCID(bytes32 name, string memory cid) external {
        require(DappNameExists(name));
        require(msg.sender == dappsIndex[name].owner);
        dappsIndex[name].cid = cid;
    }

    // @notice: index should be compute externally using getAllDapps
    function removeDapp(uint256 index, bytes32 name) public {
        require(index < dapps.length, "index is out of dapps bounds");
        require(dapps[index] == name);
        require(DappNameExists(name));
        require(msg.sender == dappsIndex[name].owner
            || hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
            || hasRole(DAO_ROLE, msg.sender)
        );
        dapps[index] = dapps[dapps.length - 1];
        dapps.pop();
        delete dappsIndex[name];
    }

    function fanExists(address _fan) public view returns (bool) {
        return fansIndex[_fan].expires > block.timestamp;
    }

    function DappNameExists(bytes32 _dapp) public view returns (bool) {
        return dappsIndex[_dapp].status == Status.Active;
    }

    function getAllFans() external view returns (address[] memory){
        return fans;
    }

    function getAllDappNames() external view returns (bytes32[] memory){
        return dapps;
    }
}

