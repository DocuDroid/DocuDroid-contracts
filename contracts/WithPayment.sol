// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WithDroid.sol";

abstract contract WithPayment is WithDroid {
	mapping(IERC20 => uint256) private acceptedTokens;

	event PaymentExecuted(address indexed by, address indexed token, uint256 amount);

	constructor() {
		IERC20 FTM_USDC = IERC20(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75);
		acceptedTokens[FTM_USDC] = 10_000000;

		IERC20 ETH_DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
		acceptedTokens[ETH_DAI] = 10_000000000000000000;

		IERC20 ETH_USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
		acceptedTokens[ETH_USDT] = 10_000000;

		IERC20 ETH_USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
		acceptedTokens[ETH_USDC] = 10_000000;

		IERC20 ETH_BUSD = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
		acceptedTokens[ETH_BUSD] = 10_000000000000000000;

		IERC20 ETH_FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
		acceptedTokens[ETH_FRAX] = 10_000000000000000000;

		IERC20 ETH_MIM = IERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
		acceptedTokens[ETH_MIM] = 10_000000000000000000;

		IERC20 ETH_ALUSD = IERC20(0xBC6DA0FE9aD5f3b0d58160288917AA56653660E9);
		acceptedTokens[ETH_ALUSD] = 10_000000000000000000;
	}

    /*******************************************************************************
	** @notice The setAcceptedTokens function allows the owner to set the price
	**	required to mint a claim with a specific token as payment.
	**	If the price is set to 0, the token is not accepted.
	** @param token The token to set the price for
	** @param price The price to set for the token
	*******************************************************************************/
    function setAcceptedTokens(address token, uint256 price) public onlyDroid {
		acceptedTokens[IERC20(token)] = price;
	}

	/*******************************************************************************
	** @notice The `takePayment()` function allows a user to make a payment to a
	**	treasury using an accepted token. It requires that the token being used for
	**	payment is accepted by the treasury, and that the payment is successful.
	** @param token The token to use for payment
	*******************************************************************************/
	function takePayment(address token) internal {
		require(acceptedTokens[IERC20(token)] > 0, "token not accepted");
        uint256 amount = acceptedTokens[IERC20(token)];

		uint256 balanceBefore = IERC20(token).balanceOf(treasury);
		require(IERC20(token).transferFrom(msg.sender, treasury, amount));
		uint256 balanceAfter = IERC20(token).balanceOf(treasury);
		require(balanceAfter - balanceBefore == amount, "payment failed");
		emit PaymentExecuted(msg.sender, token, amount);
	}
}
