// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC20{
    function totalSupply() external view returns(uint256)
}
contract MileSystem is
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply) ERC721("MileSystem", "MNRV"){
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract MileExchangeBetweenUsers {
    MileSystem public mileSystem;

    struct Offer {
        address offerer;
        uint256 amount;
        address requestedFrom;
    }

    Offer[] public offers;

    event OfferCreated(uint256 offerId, address indexed offerer, uint256 amount, address indexed requestedFrom);
    event OfferAccepted(uint256 offerId, address indexed offerer, address indexed acceptor, uint256 amount);
    event OfferCancelled(uint256 offerId, address indexed offerer);

    constructor(MileSystem _mileSystem) {
        mileSystem = _mileSystem;
    }

    function createOffer(uint256 _amount, address _requestedFrom) public {
        require(mileSystem.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        offers.push(Offer({offerer: msg.sender, amount: _amount, requestedFrom: _requestedFrom}));
        uint256 offerId = offers.length - 1;
        emit OfferCreated(offerId, msg.sender, _amount, _requestedFrom);
    }

    function acceptOffer(uint256 _offerId) public {
        require(_offerId < offers.length, "Offer not found");
        Offer storage offer = offers[_offerId];
        require(offer.requestedFrom == msg.sender, "Not the requested recipient");

        // Transfer miles from the offerer to the acceptor
        require(mileSystem.allowance(offer.offerer, address(this)) >= offer.amount, "Allowance exceeded");
        mileSystem.transferFrom(offer.offerer, msg.sender, offer.amount);

        // Remove the accepted offer
        offers[_offerId] = offers[offers.length - 1];
        offers.pop();

        emit OfferAccepted(_offerId, offer.offerer, msg.sender, offer.amount);
    }

    function cancelOffer(uint256 _offerId) public {
        require(_offerId < offers.length, "Offer not found");
        Offer storage offer = offers[_offerId];
        require(offer.offerer == msg.sender, "Not the offerer");

        // Remove the cancelled offer
        offers[_offerId] = offers[offers.length - 1];
        offers.pop();

        emit OfferCancelled(_offerId, msg.sender);
    }

    function getOffers() public view returns (Offer[] memory) {
        return offers;
    }
}

