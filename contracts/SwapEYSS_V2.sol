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

interface IOneSplitMulti {
	function getExpectedReturnWithGasMulti(
		IERC20[] memory tokens,
		uint256 amount,
		uint256[] memory parts,
		uint256[] memory flags,
		uint256[] memory destTokenEthPriceTimesGasPrices
	)
		external
		view
		returns(
			uint256[] memory returnAmounts,
			uint256 estimateGasAmount,
			uint256[] memory distribution
		);

	function swapMulti(
		IERC20[] memory tokens,
		uint256 amount,
		uint256 minReturn,
		uint256[] memory distribution,
		uint256[] memory flags
	)
		external
		payable
	returns(uint256 returnAmount);
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
		//IOneSplitMulti(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E).getExpectedReturnWithGasMulti([address(0)], msg.value, tokens, new uint[](0), new uint[](0));
		/*require(tokens.length == percentages.length, "Token list and percentages list must be the same length!");

		uint256 fee = 0;

		if (feeRecipient != address(0)) {
			fee = uint256(msg.value).div(10);
		}

		address[] memory path = new address[](2);
		path[0] = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).WETH();

		for (uint i = 0; i < tokens.length; i++) {
			require(percentages[i] <= 10000, "Percentage is over 10000");
			console.log('Swapping', uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), 'wei to:', IERC20(tokens[i]).name());
			path[1] = tokens[i];
			IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D).swapExactETHForTokens{value: uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i]))}(amountOutMin, path, msg.sender, deadline);
		}
		payable(address(feeRecipient)).transfer(fee);*/
	}
}