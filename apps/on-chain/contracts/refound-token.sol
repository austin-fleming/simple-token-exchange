// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RefoundToken {
	// ---
	// ERC20 VARS
	// ---

	uint256 public totalSupply = 1_000_000_000_000_000_000_000; // = 1000 tokens * 18 decimal places
	string public constant name = "refound coin";
	string public constant symbol = "RFD";
	uint8 public constant decimals = 18;

	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance; // person -> approved spender -> spendable allowance

	constructor() {
		balanceOf[msg.sender] = totalSupply;
	}

	// ---
	// ERC20 EVENTS
	// ---

	event Approval(address indexed owner, address indexed spender, uint256 spendingLimit);
	event Transfer(address indexed from, address indexed to, uint256 value);

	// ---
	// EXTRA EVENTS
	// ---

	event Burn(address indexed from, uint256 value);

	// ---
	// HELPER FUNCTIONS
	// ---

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a + b) >= a, "overflow error");
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require((c = a - b) <= a, "underflow error");
	}

	function _transfer(
		address from,
		address to,
		uint256 value
	) internal {
		require(to != address(0x0), "cannot transfer to 0x0");
		require(balanceOf[from] >= value, "insufficient balance");

		balanceOf[from] = sub(balanceOf[msg.sender], value); // remove from sender
		balanceOf[to] = add(balanceOf[msg.sender], value); // give to receiver

		emit Transfer(msg.sender, to, value);
	}

	// ---
	// ERC20 USE CASES
	// ---

	function transfer(address to, uint256 value) external returns (bool success) {
		_transfer(msg.sender, to, value);

		return true;
	}

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool success) {
		require(value <= allowance[from][msg.sender], "insufficient allowance"); // ensure their is sufficient allowance

		allowance[from][msg.sender] = sub(allowance[from][msg.sender], value); // deduct allowance
		_transfer(from, to, value);

		return true;
	}

	function approve(address spender, uint256 spendingLimit) external returns (bool) {
		allowance[msg.sender][spender] = spendingLimit;

		emit Approval(msg.sender, spender, spendingLimit);

		return true;
	}

	// ---
	// EXTRA USE CASES
	// ---

	function burn(uint256 value) external returns (bool) {
		require(balanceOf[msg.sender] >= value, "insufficient balance");

		balanceOf[msg.sender] = sub(balanceOf[msg.sender], value);
		totalSupply = sub(totalSupply, value);

		emit Burn(msg.sender, value);

		return true;
	}
}
