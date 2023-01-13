// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./Droid.sol";

abstract contract WithSignature is EIP712, Droid {
	mapping(address => bool) private _validator;
    mapping(address => mapping(address => uint256)) public _validatorNonces;
    mapping(address => mapping(address => bool)) public _validatorClaims;

	bytes32 private constant _VALIDATE_CLAIM_TYPEHASH = keccak256(
		"Claim(address validator,address requestor,address to,uint256 time,uint256 validatorNonce,uint256 deadline)"
	);

	constructor(string memory name, address _initialValidator) EIP712(name, "1") {
		_validator[_initialValidator] = true;
	}

    function _useValidatorNonce(address validator, address requestor) internal virtual returns (uint256 current) {
        uint256 nonce = _validatorNonces[validator][requestor];
        current = nonce;
        nonce += 1;
    }

    /*******************************************************************************
	** @dev _validateClaim allows a validator to delegate the minting of a claim
	** to another address. The validator will need to sign a message with the
	** following parameters:
	** - validator: address of the validator
	** - requestor: address of the address requesting the claim
	** - to: address which will receive the claim
	** - time: number of days the claim will be valid for
	** - deadline: timestamp after which the claim will be invalid
	** - sig: signature of the message
	*******************************************************************************/
    function _validateClaim(address validator, address requestor, address to, uint256 time, uint256 deadline, bytes calldata sig) internal {
		require(_validator[validator], "Not from validator");
        require(_validatorClaims[validator][requestor] == false, "Already unlocked");
        require(block.timestamp <= deadline, "Claim expired");
		require(time < 30, "Time too long");

		bytes32 digest = _hashTypedDataV4(
			keccak256(abi.encode(
				_VALIDATE_CLAIM_TYPEHASH,
				validator,
				requestor,
				to,
				time,
				_validatorNonces[validator][requestor],
				deadline
			))
		);
        address signer = ECDSA.recover(digest, sig);

        require(signer == validator, "Not validator");
        _validatorClaims[validator][requestor] = true;
	}

	/*******************************************************************************
	**  @notice
	**    Set the validator status for a given address. Can only be called by the
	**    Droid.
	**    The change goes into effect immediately.
	**  @param validator The address of the validator
	**  @param status The status to set to that validator
	*******************************************************************************/
	function setValidator(address validator, bool status) external onlyDroid() {
		_validator[validator] = status;
	}
}

