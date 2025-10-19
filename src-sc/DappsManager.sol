// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.30;

import {DappRank} from "./DRNK.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

// ToDo
// [x] list fans
// [x] list dapps
// [x] airdrop actors demo
// [x] mint DRNK
// [x] registerDapp (payable)
// [x] updateDappCID
// [x] removeDapp
// [x] approveDapp
// [x] burn DRNK
// [x] banDapp
// [x] expiredDapp
// [x] voteDapp
// [x] distribute DRNK
// For sprint 3 increment the deflation of ultrasound.
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
    // listingFee
    uint256 public listingFee;
    // DAOFee fixed to 1% on vote in bp
    uint256 public DAOFee;
    address public DAOAddrss;
    // burn fee % to make it ultrasound will be fixable in the future
    uint256 public burnFee; // bp

    // temporal for getting tokens to test Demo
    uint256 public topUpExpires;
    uint256 public topUpMin = 0.001 ether;

    enum Status {
        Submitted,
        Active,
        Expired,
        Banned
    }

    struct Dapp {
        string cid;
        uint256 rate; // Dr = Dapp rate
        uint256 weight_votes_sum; // sum(Vi x sqrt(Ti)) see WP.md
        uint256 weight_total_sum; // sum(sqrt(Ti)) see WP.md
        uint256 balance;
        uint256 burned;
        address owner;
        Status status;
        mapping(address => Vote) votes;
    }

    struct Fan {
        uint256 multiplier;
        uint256 expires;
    }

    struct Vote {
        uint256 vote_rate; // Vi must be between 0 and 100
        uint256 fan_weight; // Wi = sqrt(Ti)
        uint256 timestamp;
    }

    bytes32[] public dapps;
    address[] public fans;

    mapping(bytes32 => Dapp) public dappsIndex;
    mapping(address => Fan) public fansIndex;

    constructor(uint256 _listingFee, uint256 _daoFee, uint256 _burnFee, uint256 _bonus) {
        drnk = new DappRank(address(this), address(this));
        listingFee = _listingFee; // fixed price updateable
        DAOFee = _daoFee; // ToDo: based on ultrasound model
        burnFee = _burnFee; // ToDo: based on ultrasound model
        bonus = _bonus;
        DAOAddrss = msg.sender; // temporal patch should be parameter...
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // to be updated with an address as the admin role
        _grantRole(DAO_ROLE, msg.sender);
        topUpExpires = block.timestamp + 12 weeks;
    }

    function demoAirdrop(address[] calldata actors) public {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert CallerNotAdmin(msg.sender);
        }

        for (uint256 i; i < actors.length; i++) {
            _mint(actors[i], bonus);
        }
    }

    function buyDRNK() public payable {
        require(msg.value >= topUpMin, "Error: minmum price uncovered");
        require(block.timestamp <= topUpExpires);
        if (fanExists(msg.sender)) {
            _mint(msg.sender, fansIndex[msg.sender].multiplier * msg.value * 1000);
        } else {
            _mint(msg.sender, msg.value * 1000);
        }
    }

    function _mint(address to, uint256 amount) internal {
        if (fanExists(to)) {
            drnk.mint(to, amount);
            fansIndex[to].expires = block.timestamp + 4 weeks;
        } else {
            fans.push(to);
            drnk.mint(to, amount);
            // welcome bonus
            fansIndex[to] = Fan(bonus, block.timestamp + 4 weeks);
        }
    }

    function burn(uint256 _amount) public {
        require(drnk.balanceOf(msg.sender) > 0);
        require(drnk.allowance(msg.sender, address(this)) >= _amount);

        drnk.burnFrom(msg.sender, _amount);

        //if(drnk.balanceOf(msg.sender) == 0) {
        //    ToDo Remove Fan, might get index on iters out of solidity ?
        //     because gas expensive and as parameter.
        //}
    }

    function registerDapp(bytes32 name, string memory cid) public payable {
        require(msg.value >= listingFee, "Error: listing fee uncovered");
        require(!DappNameExists(name));
        // solidity gimnastics...
        Dapp storage dp = dappsIndex[name];
        dp.cid = cid;
        dp.rate = 0;
        dp.weight_votes_sum = 0;
        dp.weight_total_sum = 0;
        dp.balance = 0;
        dp.burned = 0;
        dp.owner = msg.sender;
        dp.status = Status.Submitted;

        dapps.push(name);
        _mint(msg.sender, 10 * bonus);
    }

    function approveDapp(bytes32 _name) external {
        require(DappNameExists(_name));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender));
        dappsIndex[_name].status = Status.Active;
    }

    function banDapp(bytes32 _name) external {
        require(DappNameExists(_name));
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender));
        dappsIndex[_name].status = Status.Banned;
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

    function rateDapp(bytes32 name, uint256 amount) external {}

    // @notice: index should be compute externally using getAllDapps
    function removeDapp(uint256 index, bytes32 name) public {
        require(index >= 0 && index < dapps.length, "index is out of dapps bounds");
        require(dapps[index] == name, "index do not match with dapp name");
        require(DappNameExists(name));
        require(
            msg.sender == dappsIndex[name].owner || hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
                || hasRole(DAO_ROLE, msg.sender)
        );
        dapps[index] = dapps[dapps.length - 1];
        dapps.pop();
        delete dappsIndex[name];
    }

    function removeFan(uint256 index, address fan) public {
        require(index >= 0 && index < dapps.length, "index is out of fans bounds");
        require(fans[index] == fan, "index do not match with fan");
        require(fanExists(fan));
        require(!fanIsAlive(fan)); //fan is not alive
        require(msg.sender == fan || hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(DAO_ROLE, msg.sender));
        fans[index] = fans[fans.length - 1];
        fans.pop();
        delete fansIndex[fan];
    }

    function fanIsAlive(address _fan) public view returns (bool) {
        return fansIndex[_fan].expires > block.timestamp;
    }

    function fanExists(address _fan) public view returns (bool) {
        Fan storage fn = fansIndex[_fan];
        return (!(fn.expires == 0 && fn.multiplier == 0));
    }

    function DappNameIsActive(bytes32 _dapp) public view returns (bool) {
        return dappsIndex[_dapp].status == Status.Active;
    }

    function DappNameExists(bytes32 _dapp) public view returns (bool) {
        Dapp storage dp = dappsIndex[_dapp];
        return (
            !(
                bytes(dp.cid).length == 0 && dp.rate == 0 && dp.weight_votes_sum == 0 && dp.weight_total_sum == 0
                    && dp.balance == 0 && dp.burned == 0 && dp.owner == address(0x0)
            )
        );
    }

    function voteDapp(bytes32 _name, uint256 _amount, uint256 _rate) external {
        require(DappNameExists(_name));
        require(drnk.balanceOf(msg.sender) > 0);
        require(drnk.allowance(msg.sender, address(this)) >= _amount);
        require(_rate > 0 && _rate <= 100);
        Fan memory voter = fansIndex[msg.sender];
        require(voter.expires > block.timestamp, "Voter is not a valid Fan");

        Dapp storage dapp = dappsIndex[_name];
        require(dapp.status == Status.Active, "Dapp is not active");

        // READY TO VOTE! ;)

        // increase lifetime and multiplier of Voter(fan) for the future game theory
        fansIndex[msg.sender].expires = block.timestamp + 4 weeks;
        fansIndex[msg.sender].multiplier += 1;

        //Add Vote struct to Dapp for the voter
        Vote storage vote = dapp.votes[msg.sender];
        vote.vote_rate = _rate;
        vote.fan_weight = Math.sqrt(_amount, Math.Rounding.Ceil);
        vote.timestamp = block.timestamp;

        // Square Root Weighted Voting (SRWV)
        dapp.weight_votes_sum += (vote.vote_rate * vote.fan_weight);
        dapp.weight_total_sum += vote.fan_weight;
        dapp.rate = dapp.weight_votes_sum / dapp.weight_total_sum;

        // Distribution
        //drnk.transferFrom(msg.sender, address(this), (_amount * DAOFee)); //charged on cashout
        drnk.transferFrom(msg.sender, address(this), _amount);
        drnk.approve(address(this), (_amount * burnFee / 10_000));
        drnk.burn(_amount * burnFee / 10_000);
        dapp.burned += (_amount * burnFee / 10_000);
        dapp.balance += _amount - (_amount * burnFee / 10_000) - (_amount * DAOFee / 10_000);
    }

    function dappCashOut(bytes32 _name, uint256 _amount) external {
        require(DappNameExists(_name));
        Dapp storage dapp = dappsIndex[_name];
        require(dapp.status == Status.Active, "Dapp is not active");
        require(dapp.owner == msg.sender, "Ups... You are not the dapp owner");

        drnk.approve(msg.sender, _amount - (_amount * DAOFee / 10_000));
        drnk.transfer(msg.sender, _amount - (_amount * DAOFee / 10_000)); //charged on cashout
        drnk.transfer(DAOAddrss, _amount * DAOFee / 10_000); //charged on cashout
    }

    function getAllFans() external view returns (address[] memory) {
        return fans;
    }

    function getAllDappNames() external view returns (bytes32[] memory) {
        return dapps;
    }

    // ToDo check with the Solidity Gimnastics storage how to handle
    //function getDappInfoStruct(bytes32 _dapp) public view returns(Dapp calldata) {
    //    require(DappNameExists(_dapp));
    //    return dappsIndex[_dapp];
    //}

    function getDappInfo(bytes32 _dapp)
        public
        view
        returns (
            string memory cid,
            uint256 rate,
            uint256 weight_votes_sum,
            uint256 weight_total_sum,
            uint256 balance,
            uint256 burned,
            address owner,
            bytes32 status
        )
    {
        require(DappNameExists(_dapp));
        Dapp storage dp = dappsIndex[_dapp];
        return (
            dp.cid,
            dp.rate,
            dp.weight_votes_sum,
            dp.weight_total_sum,
            dp.balance,
            dp.burned,
            dp.owner,
            _mapDappStatusToBytes32(dp.status)
        );
    }

    function _mapDappStatusToBytes32(Status status) internal pure returns (bytes32) {
        if (status == Status.Submitted) {
            return bytes32("Submitted");
        } else if (status == Status.Active) {
            return bytes32("Active");
        } else if (status == Status.Expired) {
            return bytes32("Expired");
        } else if (status == Status.Banned) {
            return bytes32("Banned");
        } else {
            revert UnknownStatus(status);
        }
    }

    function getFanInfo(address _fan) external view returns (uint256, uint256) {
        Fan storage fanData = fansIndex[_fan];
        return (fanData.expires, fanData.multiplier);
    }

    function getFanInfoStruct(address _fan) external view returns (Fan memory) {
        require(fanExists(_fan));
        return fansIndex[_fan];
    }
}
