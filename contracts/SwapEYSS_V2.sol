// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface IRouter {
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function WETH() external pure returns (address);
	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
	function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}

interface IERC20 {
	function name() external view returns (string memory);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

interface IBalancerExchange {
	struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint    swapAmount; // tokenInAmount / tokenOutAmount
        uint    limitReturnAmount; // minAmountOut / maxAmountIn
        uint    maxPrice;
    }

	function smartSwapExactIn(
		TokenInterface tokenIn,
		TokenInterface tokenOut,
		uint totalAmountIn,
		uint minTotalAmountOut,
		uint nPools
	)
		external payable
		returns (uint totalAmountOut);

	function batchSwapExactIn(
		Swap[] memory swaps,
		TokenInterface tokenIn,
		TokenInterface tokenOut,
		uint totalAmountIn,
		uint minTotalAmountOut
	)
		external payable
		returns (uint totalAmountOut);

	function viewSplitExactIn(
		address tokenIn,
		address tokenOut,
		uint swapAmount,
		uint nPools
	)
		external view
		returns (Swap[] memory swaps, uint totalOutput);
}

contract SwapEYSS_V2 is OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;
	address public feeRecipient;

	function initialize(address _feeRecipient) public initializer {
		OwnableUpgradeable.__Ownable_init();
		feeRecipient = _feeRecipient;
	}

	function changeRecipient(address _feeRecipient) public onlyOwner {
		feeRecipient = _feeRecipient;
	}

	function swapTokens(address[] calldata tokens, uint[] calldata percentages, uint amountOutMin, uint deadline) public payable {
		require(tokens.length == percentages.length, "Token list and percentages list must be the same length!");

		uint256 fee = 0;
		if (feeRecipient != address(0)) {
			fee = uint256(msg.value).div(10);
		}

		uint output;
		uint[] memory amounts;
		address[] memory paths = new address[](2);
		paths[0] = (IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).WETH());

		for (uint i = 0; i < tokens.length; i++) {
			paths[1] = (tokens[i]);
			(amounts) = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).getAmountsOut(
				uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])),
				paths
			);
			//console.log(amounts[1], "is the price for", IERC20(tokens[i]).name(), 'on Uniswap V2');

			(, output) = IBalancerExchange(0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21)
				.viewSplitExactIn(
					0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // Ether address
					tokens[i], // Token address
					uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), // %
					2 // nPools
			);
			//console.log(output, "is the price for", IERC20(tokens[i]).name(), 'on Balancer');

			if (amounts[1] > output) {
				//console.log('Buying on Uniswap');				
				IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
					.swapExactETHForTokens{
						value: uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i]))
					}(
						amountOutMin,
						paths,
						msg.sender,
						deadline);
			} else {
				//console.log('Buying on Balancer');				
				(output) = IBalancerExchange(0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21)
					.smartSwapExactIn{
						value: uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i]))
					}(
						TokenInterface(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
						TokenInterface(tokens[i]),
						uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), // %
						amountOutMin,
						2);
				//console.log('Got', output, IERC20(tokens[i]).name(), 's');
			}
		}
		payable(address(feeRecipient)).transfer(fee);
		payable(address(msg.sender)).transfer(address(this).balance);
	}
}