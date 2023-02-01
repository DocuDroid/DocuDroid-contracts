// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WithSignature.sol";
import "./WithPayment.sol";
import "./WithDroid.sol";

contract Claim is ERC721, ERC721Enumerable, EIP712, WithDroid, WithSignature, WithPayment {
	uint256 public nextID = 1;
	uint256 constant MONTH = 31 days;
	string private baseURI = '';
	bool public isPaused = false;

	mapping(uint256 => uint256) private _expiration;
	mapping(uint256 => uint256) private _edition;
	mapping(uint256 => uint256) private _editionSupply;

	event Claimed(address indexed owner, uint256 claimID, uint256 edition, uint256 expiration);
	event DelegateClaim(address indexed validator, address indexed requestor, address indexed to, uint256 time);

    constructor(address _initialValidator) ERC721("Claim Access Control", "CAC") WithSignature("Claim Access Control", _initialValidator) {}

	function _claim(address to, uint duration) private {
		require(!isPaused, "paused");

		if (editionBumpThreshold < block.timestamp) {
			currentEdition++;
			editionBumpThreshold = block.timestamp + defaultEditionBumpInterval;
		}

		uint256 _nextID = nextID;
		nextID++;
		_expiration[_nextID] = block.timestamp + duration;
		_edition[_nextID] = currentEdition;
		_editionSupply[currentEdition] += 1;
		_safeMint(to, _nextID);
		emit Claimed(to, _nextID, currentEdition, _expiration[_nextID]);
	}

	/*******************************************************************************
	**  @dev: mint a new claim in exchange of DAI. The claim will be valid for 30
	**  days
	*******************************************************************************/
	function claim(address tokenAsPayment) public {
		takePayment(tokenAsPayment);
		_claim(msg.sender, MONTH);
	}

	/*******************************************************************************
	**  @dev: mint a new claim in exchange of DAI. The claim will be valid for 30
	**  days. The claim can be minted for another address.
	**  @param to: address which will receive the claim
	*******************************************************************************/
	function claimFor(address tokenAsPayment, address to) public {
		takePayment(tokenAsPayment);
		_claim(to, MONTH);
	}

	/*******************************************************************************
	**  @dev: mint a new claim for free. Can only be called by the Droid
	**  @param to: address which will receive the claim
	*******************************************************************************/
	function droidClaimFor(address to, uint numberOfDays) public onlyDroid {
		_claim(to, (numberOfDays * 1 days));
	}

	/*******************************************************************************
	** @dev ClaimFromValidator allows a validator to delegate the minting of a claim
	** to another address. The validator will need to sign a message with the
	** following parameters:
	** - validator: address of the validator
	** - requestor: address of the address requesting the claim
	** - to: address which will receive the claim
	** - time: number of days the claim will be valid for
	** - deadline: timestamp after which the claim will be invalid
	** - sig: signature of the message
	** If the signature is valid and comes from the validator, the claim will be
	** minted for to and the validator will be marked as having delegated a claim
	** to requestor.
	*******************************************************************************/
    function claimFromValidator(address validator, address requestor, address to, uint256 time, uint256 deadline, bytes calldata sig) public virtual {
		require(balanceOf(requestor) == 0, "Already claimed");
		_validateClaim(validator, requestor, to, time, deadline, sig);
		_claim(to, (time * 1 days));
		emit DelegateClaim(validator, requestor, to, time);
    }

	/*******************************************************************************
	**  @dev: replace the baseURI with a new one. Can only be called by the Droid.
	**  @param _newURI: new baseURI
	*******************************************************************************/
	function	setBaseURI(string memory _newURI) public onlyDroid() {
		baseURI = _newURI;
	}

	/*******************************************************************************
	**  @dev: indicate whether the contract is paused or not. Can only be called by
	**  the Droid.
	**  @param _shouldPause: true if the contract should be paused, false otherwise
	*******************************************************************************/
	function	pauseClaims(bool _shouldPause) public onlyDroid() {
		isPaused = _shouldPause;
	}

	/**********************************************************************************************
	**  READ ONLY FUNCTIONS
	***********************************************************************************************/

	/**********************************************************************************************
	**  @dev Returns the expiration date of a claim
	**  @param _claimID uint256 ID of the claim to query the expiration of
	**********************************************************************************************/
	function expiration(uint256 _claimID) public view returns (uint256) {
		return _expiration[_claimID];
	}

	/**********************************************************************************************
	**  @dev Returns the edition of a claim
	**  @param _claimID uint256 ID of the claim to query the edition of
	**********************************************************************************************/
	function edition(uint256 _claimID) public view returns (uint256) {
		return _edition[_claimID];
	}

	/**********************************************************************************************
	**  @dev Indicate if the claim is expired or not
	**  @param _claimID uint256 ID of the claim to check the expiration of
	**********************************************************************************************/
	function isExpired(uint256 _claimID) public view returns (bool) {
		return _expiration[_claimID] < block.timestamp;
	}

	/**********************************************************************************************
	**  @dev For a given claimID, returns the owner and expiration date
	**  @param _claimID uint256 ID of the claim to query the owner of
	**********************************************************************************************/
	function claimData(uint256 _claimID) external view returns (address, uint256, uint256, bool) {
		return (ownerOf(_claimID), expiration(_claimID), edition(_claimID), isExpired(_claimID));
	}

	/**********************************************************************************************
	**  @dev Returns the number of claims minted for a given edition
	**  @param edition uint256 ID of the edition to query the supply of
	**********************************************************************************************/
	function editionSupply(uint256 _editionID) public view returns (uint256) {
		return _editionSupply[_editionID];
	}

	/**********************************************************************************************
	**  REQUIRED OVERRIDES
	***********************************************************************************************/
	function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

	function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
		internal
		override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId, batchSize);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		override(ERC721, ERC721Enumerable)
		returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}

