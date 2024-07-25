// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MinervaToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract buy_sell_Token is Ownable {
    MinervaToken minervaToken;
    uint256 public tokensPerCoin = 100;
    uint256 public maxTokensPerPurchase = 1000 *(10**18); // 1000 tokens (no need to multiply by 10**18)
    uint256 public maxTokensPerAddress = 5000  *(10**18); // 5000 tokens (no need to multiply by 10**18)
    uint256 public sellDiscountPercent = 2; // 2% discount

    event BuyTokens(address buyer, uint256 amountOfCoin, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfCoin);

    constructor(address tokenAddress) Ownable(msg.sender) {
        minervaToken = MinervaToken(tokenAddress);
    }

    function setTokensPerCoin(uint256 newRate) public onlyOwner {
        tokensPerCoin = newRate;
    }

    function setMaxTokensPerPurchase(uint256 newLimit) public onlyOwner {
        maxTokensPerPurchase = newLimit* (10 **18);
    }

    function setMaxTokensPerAddress(uint256 newLimit) public onlyOwner {
        maxTokensPerAddress = newLimit* (10 ** 18);
    }

    function setSellDiscountPercent(uint256 newDiscount) public onlyOwner {
        sellDiscountPercent = newDiscount;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance() public view returns (uint256) {
        return minervaToken.balanceOf(address(this));
    }


    function buyTokens() public payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Send Coin to buy some tokens");

        uint256 amountToBuy = msg.value * tokensPerCoin;
        require(amountToBuy <= maxTokensPerPurchase, "Exceeds maximum tokens per purchase");

        uint256 contractBalance = minervaToken.balanceOf(address(this));
        require(contractBalance >= amountToBuy, "Vendor contract has not enough tokens in its balance");

        uint256 userBalance = minervaToken.balanceOf(msg.sender);
        require(userBalance + amountToBuy <= maxTokensPerAddress, "Exceeds maximum tokens per address");

        (bool sent) = minervaToken.transfer(msg.sender, amountToBuy);
        require(sent, "Failed to transfer token to user");

        emit BuyTokens(msg.sender, msg.value, amountToBuy);

        return amountToBuy;
    }

    function sellTokens(uint256 tokenAmount) public returns (uint256 coinAmount) {
        tokenAmount = tokenAmount * (10 ** 18);
        require(tokenAmount > 0, "Specify amount of tokens to sell");
        require(minervaToken.balanceOf(msg.sender) >= tokenAmount, "Insufficient token balance");

        uint256 amountToPay = (tokenAmount * (100 - sellDiscountPercent)) / (100 * tokensPerCoin);
        require(address(this).balance >= amountToPay, "Insufficient Coin balance in contract");

        (bool sent) = minervaToken.transferFrom(msg.sender, address(this), tokenAmount);
        require(sent, "Failed to transfer token to contract");

        (bool coinSent,) = msg.sender.call{value: amountToPay}("");
        require(coinSent, "Failed to send Coin to user");

        emit SellTokens(msg.sender, tokenAmount, amountToPay);

        return amountToPay;
    }

    function withdraw() public onlyOwner {
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");

        (bool sent,) = msg.sender.call{value: ownerBalance}("");
        require(sent, "Failed to send user balance back to the owner");
    }

    function withdrawTokens(uint256 amount) public onlyOwner {
        uint256 tokenBalance = minervaToken.balanceOf(address(this));
        require(tokenBalance >= amount * (10**18), "Vendor contract has not enough tokens to withdraw");

        (bool sent) = minervaToken.transfer(msg.sender, amount * (10**18));
        require(sent, "Failed to transfer tokens to the owner");
    }
}
