// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface IRouter {
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function WETH() external pure returns (address);
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

		IBalancerExchange(0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21)
			.smartSwapExactIn{
				value: msg.value
			}(
				TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2),
				TokenInterface(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE),
				msg.value,
				1,
				1);

		/*uint totalOutput;
		for (uint i = 0; i < tokens.length; i++) {
			require(percentages[i] <= 10000, "Percentage is over 10000");
			console.log(uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])));

			IBalancerExchange(0x3E66B66Fd1d0b02fDa6C811Da9E0547970DB2f21)
				.viewSplitExactIn(
					0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, // Ether address
					tokens[i], // Token address
					uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), // %
					1 // nPools
			);


			console.log(totalOutput);

			console.log('Consulting price for', IERC20(tokens[i]).name());
			
			//console.log(uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), 'wei =', totalOutput, IERC20(tokens[i]).name());
			console.log('Swapping', uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), 'wei to:', IERC20(tokens[i]).name());
				
			console.log('Have', IERC20(tokens[i]).balanceOf(msg.sender), IERC20(tokens[i]).name());
			//require(gottenTokens > 0, "Didn't receive any tokens!");
		}
		payable(address(feeRecipient)).transfer(fee);
		payable(address(msg.sender)).transfer(address(this).balance);*/
	}
}