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

/*interface IAggregationRouterV3 {
	struct SwapDescription {
		IERC20 srcToken;
		IERC20 dstToken;
		address srcReceiver;
		address dstReceiver;
		uint256 amount;
		uint256 minReturnAmount;
		uint256 flags;
		bytes permit;
	}

	function swap(
		IAggregationExecutor caller,
		SwapDescription calldata desc,
		bytes calldata data
	)
		external
		payable
		returns (uint256 returnAmount, uint256 gasLeft);
}*/

interface IOneSplitAudit {
	function getExpectedReturnWithGas(
		IERC20 fromToken,
		IERC20 toToken,
		uint256 amount,
		uint256 parts,
		uint256 disableFlags,
		uint256 destTokenEthPriceTimesGasPrice
	)
	external
	view
	returns(
		uint256 returnAmount,
		uint256 estimateGasAmount,
		uint256[] memory distribution
	);

	function getExpectedReturn(
		IERC20 fromToken,
		IERC20 toToken,
		uint256 amount,
		uint256 parts,
		uint256 disableFlags
	)
	external
	view
	returns(
		uint256 returnAmount,
		uint256[] memory distribution
	);

	function swap(
		IERC20 fromToken,
		IERC20 toToken,
		uint256 amount,
		uint256 minReturn,
		uint256[] memory distribution,
		uint256 disableFlags
	) external payable returns(uint256);
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
		// 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E - OneSplitAudit address (March 2020)
		// 0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e - OneSplitAudit BETA address (July 2020)
		require(tokens.length == percentages.length, "Token list and percentages list must be the same length!");
	
		uint256 fee = 0;
		if (feeRecipient != address(0)) {
			fee = uint256(msg.value).div(10);
		}
		uint(deadline);
		uint returnAmount;
		uint estimateGasAmount;
		uint[] memory distribution;
		uint gottenTokens;
		//IAggregationRouterV3.SwapDescription memory info;
		for (uint i = 0; i < tokens.length; i++) {
			require(percentages[i] <= 10000, "Percentage is over 10000");

			/*info.srcToken = IERC20(address(0));
			info.dstToken = IERC20(tokens[i]);
			info.srcReceiver = address(tokens[i]);
			info.dstReceiver = address(msg.sender);
			info.amount = uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i]));
			info.minReturnAmount = uint256(1);
			info.flags = uint256(0);
			info.permit = bytes();

			IAggregationRouterV3(0x11111112542D85B3EF69AE05771c2dCCff4fAa26).swap()*/

			console.log('Consulting price for', IERC20(tokens[i]).name());




			// Initial estimation
			/*(returnAmount, distribution) = IOneSplitAudit(
				0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e
			).getExpectedReturn(
				IERC20(address(0)),
				IERC20(tokens[i]),
				uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])),
				20, 0x0);*/


				// Estimation with gas prices
				// Works the same as getExpectedReturnWithGas but doesn't have estimateGasAmount in the returns
				// Doesn't have the last argument either
				(returnAmount, estimateGasAmount, distribution) = IOneSplitAudit(
					0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e
				).getExpectedReturnWithGas(
					IERC20(address(0)),
					IERC20(tokens[i]),
					uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])),
					20, 0x0, gasleft());

				// Debugging
				console.log('-', gasleft());
				for (uint j = 0; j < distribution.length; j++) {
					console.log(j, ':', distribution[j]);
				}
				console.log(uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), 'wei =', returnAmount, IERC20(tokens[i]).name());
				console.log('Swapping', uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), 'wei to:', IERC20(tokens[i]).name());
				
				// Swap
				gottenTokens = IOneSplitAudit(
					0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e
				).swap{
					value: uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])) // This was within a loop so assume this is msg.value
				}(
					IERC20(address(0)), // ETH
					IERC20(tokens[i]), // The token you're swapping
					uint256(msg.value).sub(fee).div(10000).mul(uint(percentages[i])), // ETH to swap
					amountOutMin, // I just use 1
					distribution, // The result from getExpectedReturn
					0x0); // 0


			console.log('Got', gottenTokens, IERC20(tokens[i]).name());
			console.log('Have', IERC20(tokens[i]).balanceOf(msg.sender), IERC20(tokens[i]).name());
			//require(gottenTokens > 0, "Didn't receive any tokens!");
		}
		payable(address(feeRecipient)).transfer(fee);
		payable(address(msg.sender)).transfer(address(this).balance);
	}
}