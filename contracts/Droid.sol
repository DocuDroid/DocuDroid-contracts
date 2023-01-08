// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Droid {
	address public droid;
	address public treasury;
	address public pendingDroid;
	uint256 public currentEdition;
	uint256 public claimPrice = 1000;

	constructor() {
		droid = msg.sender;
		treasury = msg.sender;
	}

	modifier onlyDroid() {
		require(msg.sender == droid, "!owner");
		_;
	}
	modifier onlyPendingDroid() {
		require(msg.sender == pendingDroid, "!authorized");
		_;
	}

	/*******************************************************************************
	**  @notice
	**    Nominate a new address to use as Droid.
	**    The change does not go into effect immediately. This function sets a
	**    pending change, and the management address is not updated until
	**    the proposed Droid address has accepted the responsibility.
	**    This may only be called by the current Droid address.
	**  @param _droid The address requested to take over the role.
	*******************************************************************************/
	function setDroid(address _droid) public onlyDroid() {
		pendingDroid = _droid;
	}

	/*******************************************************************************
	**  @notice
	**    Once a new droid address has been proposed using setDroid(),
	**    this function may be called by the proposed address to accept the
	**    responsibility of taking over the role for this contract.
	**    This may only be called by the proposed Droid address.
	**  @dev
	**    setDroid() should be called by the existing droid address,
	**    prior to calling this function.
	*******************************************************************************/
	function acceptDoid() public onlyPendingDroid() {
		droid = msg.sender;
	}

	/*******************************************************************************
	**  @notice
	**    Nominate a new address to use as treasury. . Can only be called by
	**    the Droid.
	**    The change goes into effect immediately.
	**  @param _treasury The address requested to take over the role.
	*******************************************************************************/
	function setTreasury(address _treasury) public onlyDroid() {
		treasury = _treasury;
	}

	/*******************************************************************************
	**  @notice
	**    Change the price for one claim. Can only be called by the Droid.
	**    The change goes into effect immediately.
	**  @param _treasury The address requested to take over the role.
	*******************************************************************************/
	function setClaimPrice(uint256 _claimPrice) public onlyDroid() {
		claimPrice = _claimPrice;
	}

	/*******************************************************************************
	**  @notice
	**    Increment the edition. Can only be called by the Droid.
	**    The change goes into effect immediately.
	*******************************************************************************/
	function bumpEdition() public onlyDroid() {
		currentEdition++;
	}
}
