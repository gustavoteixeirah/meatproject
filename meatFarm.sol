// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./meatToken.sol";

contract MeatFarm {

    //uint256[] public tokenIndex;
    mapping(address => uint256[] ) public stakingBalance;
    mapping(address => bool) public isStaking;
    mapping(address => uint256) public startTime;
    mapping(address => uint256) public meatBalance;

    string public name = "MeatFarm";

    IERC721 public cdnoNFT;
    MeatToken public meatToken;

    event Stake(address indexed from, uint256 indexed);
    event Unstake(address indexed from, uint256 indexed);
    event YieldWithdraw(address indexed to, uint256 amount);

    constructor(
        IERC721 _cdnoNFT,
        MeatToken _meatToken
        ) {
            cdnoNFT = _cdnoNFT;
            meatToken = _meatToken;
        }

    //===================STAKE========================

    function stake(uint256 tokenId) public {
        require(
            cdnoNFT.balanceOf (msg.sender) > 0, 
            "You cannot stake zero NFT");
            
        if(isStaking[msg.sender] == true){     
            uint256 toTransfer = calculateYieldTotal(msg.sender);
            meatBalance[msg.sender] += toTransfer;
        }

        cdnoNFT.transferFrom(msg.sender, address(this), tokenId);
        //tokenIndex.push(tokenId);
        stakingBalance[msg.sender].push(tokenId);
        startTime[msg.sender] = block.timestamp;
        isStaking[msg.sender] = true;
        emit Stake(msg.sender, tokenId);
    }
 

    //===================UNSTAKE========================


    function unstake(uint256 tokenId) public {
        require(
            isStaking[msg.sender] = true &&
            stakingBalance[msg.sender].length >= 0, 
            "Nothing to unstake"
        );
        uint256 yieldTransfer = calculateYieldTotal(msg.sender);
        startTime[msg.sender] = block.timestamp;
         cdnoNFT.approve(msg.sender, tokenId);
         cdnoNFT.safeTransferFrom(address(this), msg.sender, tokenId);
        //tokenIndex.pop();
        // stakingBalance[msg.sender].pop();
        
        //================CUSTOM========

        // require(tokenId < stakingBalance[msg.sender].length  , "index out of bound");

        for (uint256 i = tokenId; i < stakingBalance[msg.sender].length - 1; i++) 
            stakingBalance[msg.sender][i] = stakingBalance[msg.sender][i + 1];

        stakingBalance[msg.sender].pop();
 


        meatBalance[msg.sender] += yieldTransfer;
        if(stakingBalance[msg.sender].length == 0){
            isStaking[msg.sender] = false;
        }
        emit Unstake(msg.sender, tokenId);
    }


    function callAll() public view returns(uint256[] memory){
        return stakingBalance[msg.sender];    
        
    }


    function calculateYieldTime(address user) public view returns(uint256){
        uint256 end = block.timestamp;
        uint256 totalTime = end - startTime[user];
        return totalTime;
    }

    function calculateYieldTotal(address user) public view returns(uint256) {
        uint256 time = calculateYieldTime(user) * 10**18;
        uint256 rate = 86400;
        uint256 timeRate = time / rate;
        uint256 rawYield = ((stakingBalance[user].length * 10000) * timeRate) / 10**18;
        return rawYield;
    } 

    function withdrawYield() public {
        uint256 toTransfer = calculateYieldTotal(msg.sender);

        require(
            toTransfer > 0 ||
            meatBalance[msg.sender] > 0,
            "Nothing to withdraw"
            );
            
        if(meatBalance[msg.sender] != 0){
            uint256 oldBalance = meatBalance[msg.sender];
            meatBalance[msg.sender] = 0;
            toTransfer += oldBalance;
        }

        startTime[msg.sender] = block.timestamp;
        meatToken.mint(msg.sender, toTransfer);
        emit YieldWithdraw(msg.sender, toTransfer);
    } 
}