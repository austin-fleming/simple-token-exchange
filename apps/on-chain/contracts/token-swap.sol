// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./refound-token.sol";

// TODO: ownable
// TODO: withdrawable
// TODO: fees total -- withdrawable amount should never exceed this, else collateral will fall too low.
contract TokenSwap {
	uint256 internal constant MAX_UINT = type(uint256).max;

	string public constant name = "refound token swap";
	RefoundToken internal token;
	uint256 public rate;
	uint256 private totalFees;
	uint256 private feePercent = 2;

	event TokensBought(address account, address token, uint256 quantity, uint256 rate);
	event TokensSold(address account, address token, uint256 quantity, uint256 rate);

	// ---
	// HELPERS
	// TODO: DRYify helpers
	// ---

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a + b) >= a, "overflow error");
	}

	function subtract(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a - b) <= a, "underflow error");
	}

	function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
		// just checking a saves gas
		if (a == 0) {
			return 0;
		}

		uint256 c = a * b;
		require(c / a == b, "overflow error");

		return c;
	}

	function divide(uint256 numerator, uint256 denominator) internal pure returns (uint256) {
		require(denominator > 0, "underflow error");

		return numerator / denominator;
	}

	function _calculateTransactionFee(uint256 transactionCost) internal view returns (uint256) {
		return (multiply(transactionCost, 100) / feePercent) / 100;
	}

	// ---
	// METHODS
	// ---

	function buy() external payable returns (bool) {
		uint256 fee = _calculateTransactionFee(msg.value); // get transaction fee for the amount of eth provided
		totalFees = add(totalFees, fee); // add to record of fees paid

		// TODO: double check this math
		uint256 tokensAfterFee = multiply(subtract(msg.value, fee), rate); // tokens to buy = ( eth paid - transaction fee ) * exchange rate

		require(token.balanceOf(address(this)) >= tokensAfterFee, "swap has insufficient tokens");

		require(token.transfer(msg.sender, tokensAfterFee), "failed to transfer tokens"); // send to user

		emit TokensBought(msg.sender, address(token), tokensAfterFee, rate);
		return true;
	}

	function sell(uint256 tokensToSell) external returns (bool) {
		require(token.balanceOf(msg.sender) >= tokensToSell, "insufficient balance");

		uint256 ethValueOfTokens = divide(tokensToSell, rate);
		uint256 fees = _calculateTransactionFee(ethValueOfTokens);

		totalFees = add(totalFees, fees);

		uint256 ethAfterFee = ethValueOfTokens - fees;

		require(address(this).balance >= ethAfterFee, "swap has insufficient eth");

		require(
			token.transferFrom(msg.sender, address(this), tokensToSell),
			"failed to recieve tokens"
		); // get tokens from user

		(bool ethTransferSucceeded, ) = payable(msg.sender).call{value: ethAfterFee}("");
		require(ethTransferSucceeded, "failed to send eth"); // send Eth to user

		emit TokensSold(msg.sender, address(token), tokensToSell, rate);
		return true;
	}

	// ---
	// OWNER ONLY
	// TODO: extend ownable modifiers
	// ---

	function surplusFunds() external view returns (uint256) {
		return totalFees;
	}

	/* 
  function withdrawSurplusFunds(uint256 amountToWithdraw) extendal ownerOnly returns (bool success) {
    require(amountToWithdraw <= totalFees);
    totalFees -= amountToWithdraw
    
    // transfer(amountToWithdraw)

    return true
  }
   */

	function setTransactionFeePercent(uint256 newTransactionFee) external returns (bool) {
		feePercent = newTransactionFee;

		return true;
	}

	function setRate(uint256 newRate) external returns (bool) {
		rate = newRate;

		return true;
	}
}
