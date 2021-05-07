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

interface IERC20 {
	function name() external view returns (string memory);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

contract SwapEYSS_V1 is OwnableUpgradeable {
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

		address[] memory path = new address[](2);
		path[0] = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).WETH();

		for (uint i = 0; i < tokens.length; i++) {
			require(percentages[i] <= 10000, "Percentage is over 10000");
			//console.log('Swapping', uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), 'wei to:', IERC20(tokens[i]).name());
			path[1] = tokens[i];
			IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactETHForTokens{value: uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i]))}(amountOutMin, path, msg.sender, deadline);
		}
		payable(address(feeRecipient)).transfer(fee);
		payable(address(msg.sender)).transfer(address(this).balance);
	}
}