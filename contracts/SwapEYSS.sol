// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface IRouter {
	function swapExactETHForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
	function WETH() external pure returns (address);
}

interface IERC20 {
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
}

contract SwapEYSS is OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;
	address private feeRecipient;

	function initialize() public initializer {
		OwnableUpgradeable.__Ownable_init();
	}

	modifier _getBestRoute() {
		_;
	}

	function swapTokens(address token, uint amountIn, uint amountOutMin, uint deadline) public payable _getBestRoute {
		IRouter bestRoute = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		uint256 memory fee = uint256(amountIn).div(10);
		uint256 memory sentAmount = uint256(amountIn).sub(fee);

		IERC20(token).approve(address(bestRoute), sentAmount);
		IERC20(token).transferFrom(msg.sender, address(bestRoute), sentAmount);
		
		address[] memory path = new address[](2);
		path[0] = token;
		path[1] = bestRoute.WETH();
		bestRoute.swapExactETHForTokens(sentAmount, amountOutMin, path, msg.sender, deadline);

		IERC20(token).approve(feeRecipient, fee);
		IERC20(token).transferFrom(msg.sender, feeRecipient, fee);
	}
}