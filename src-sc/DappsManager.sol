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

contract DappsManager is AccessControl {
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    DappRank public drnk;

    error CallerNotAdmin(address caller);
    error CallerNotDAO(address caller);
    error UnknownStatus(Status unknown);

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

    bytes32[] public dapps;
    address[] public fans;

    mapping (bytes32 => Dapp) public dappsIndex;
    mapping (address => Fan) public fansIndex;

    constructor(uint _fee, uint _bonus) {
        drnk = new DappRank(address(this), address(this));
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

        for(uint i; i < actors.length; i++) {
            _mint(actors[i], bonus);
        }
    }

    function _mint(address to, uint256 amount) internal {
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
        require(index >= 0 && index < dapps.length, "index is out of dapps bounds");
        require(dapps[index] == name, "index do not match with dapp name");
        require(DappNameExists(name));
        require(msg.sender == dappsIndex[name].owner
            || hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
            || hasRole(DAO_ROLE, msg.sender)
        );
        dapps[index] = dapps[dapps.length - 1];
        dapps.pop();
        delete dappsIndex[name];
    }

    function fanIsAlive(address _fan) public view returns (bool) {
        return fansIndex[_fan].expires > block.timestamp;
    }

    function fanExists(address _fan) public view returns (bool) {
        Fan storage fn = fansIndex[_fan];
        return (fn.expires == 0 && fn.multiplier == 0);
    }

    function DappNameIsActive(bytes32 _dapp) public view returns (bool) {
        return dappsIndex[_dapp].status == Status.Active;
    }

    function DappNameExists(bytes32 _dapp) public view returns (bool) {
        Dapp storage dp = dappsIndex[_dapp];
        return(!(bytes(dp.cid).length == 0
               && dp.fans_score == 0
               && dp.decentralized_score == 0
               && dp.total_burned == 0
               && dp.owner == address(0x0)
              ));
    }

    function getAllFans() external view returns (address[] memory){
        return fans;
    }

    function getAllDappNames() external view returns (bytes32[] memory){
        return dapps;
    }

    //function getDappInfo(bytes32 _dapp) external view returns(
    //    string memory cid,
    //    uint256 fans_score,
    //    uint256 decentralized_score,
    //    uint256 total_burned,
    //    address owner,
    //    Status status
    //) {
    //    return dappsIndex[_dapp];
    //}

    function getDappInfoStruct(bytes32 _dapp) public view returns(Dapp memory) {
        require(DappNameExists(_dapp));
        return dappsIndex[_dapp];
    }

    function getDappInfo(bytes32 _dapp) public view returns(
        string memory cid,
        uint256 fans_score,
        uint256 decentralized_score,
        uint256 total_burned,
        address owner,
        bytes32 status
    ) {
        require(DappNameExists(_dapp));
        Dapp storage dp = dappsIndex[_dapp];
        return(
            dp.cid,
            dp.fans_score,
            dp.decentralized_score,
            dp.total_burned,
            dp.owner,
            _mapDappStatusToBytes32(dp.status)
        );
    }

    function _mapDappStatusToBytes32(Status status) internal pure returns(bytes32) {
        if (status == Status.Submitted) {
            return bytes32("Submitted");
        } else if (status == Status.Active) {
            return bytes32("Active");
        } else if (status == Status.Expired) {
            return bytes32("Expired");
        } else if (status == Status.Banned) {
            return bytes32("Banned");
        } else
            revert UnknownStatus(status);
    }

    function getFanInfo(address _fan) external view returns(uint256, uint256) {
        Fan storage fanData = fansIndex[_fan];
        return (fanData.expires, fanData.multiplier);
    }

    function getFanInfoStruct(address _fan) external view returns(Fan memory) {
        require(fanExists(_fan));
        return fansIndex[_fan];
    }
}
