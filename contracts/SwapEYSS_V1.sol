// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

interface IRouter {
	function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
	function WETH() external pure returns (address);
}

interface IERC20 {
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

	function swapTokens(address token, uint amountOutMin, uint deadline) public payable {
		uint256 fee = 0;

		if (feeRecipient != address(0)) {
			fee = uint256(msg.value).div(10);
		}

		address[] memory path = new address[](2);
		path[0] = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).WETH();
		path[1] = token;

		IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactETHForTokens{value: uint256(msg.value).sub(fee)}(amountOutMin, path, msg.sender, deadline);

		payable(address(feeRecipient)).transfer(fee);
		//console.log('Done! - Balance:');
		//console.log(IERC20(token).balanceOf(msg.sender));
	}
}

