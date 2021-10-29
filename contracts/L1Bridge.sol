// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract L1Bridge {
    using SafeMath for uint256;

    // Original token on L1 network (Ethereum mainnet #1)
    IERC20 public l1Token;

    // L2 mintable + burnable token that acts as a twin of L1 token on L2
    IERC20 public l2Token;

    // L1Token amounts locked on the bridge
    mapping(address => uint256) public balances;

    event DepositInitiated(address indexed l1Token, address indexed _from, address indexed _to, uint256 _amount);
    event Withdraw(address owner, uint256 amount);

    constructor(IERC20 _l1Token, IERC20 _l2Token) {
        require(address(_l1Token) != address(0), "ZERO_TOKEN");
        require(address(_l2Token) != address(0), "ZERO_TOKEN");
        l1Token = _l1Token;
        l2Token = _l2Token;
    }

    /**
     * @notice Initiates a deposit from L1 to L2; callable by any tokenholder.
     * The amount should be approved by the holder
     * @param _to L2 address of destination
     * @param _amount Token amount to bridge
     */
    function outboundTransfer(address _to, uint256 _amount) external {
        require(_amount > 0, "Cannot deposit 0 Tokens");
        balances[msg.sender] = balances[msg.sender].add(_amount);
        require(l1Token.transferFrom(msg.sender, address(this), _amount), "Insufficient Token Allowance");
        emit DepositInitiated(address(l1Token), msg.sender, _to, _amount);
    }

    /**
     * @dev Withdraw the "quantity" of reserved DAO1 tokens, reducing the balance of tokens on the contract.
     * @param _amount Withdraw amount
     * Requirements:
     *
     * - amount cannot be zero.
     * - the caller must have a balance on contract of at least `amount`.
     */

    function withdraw(uint256 _amount) public payable {
        require(_amount > 0, "Cannot withdraw 0 Tokens!");

        require(balances[msg.sender] >= _amount, "Invalid amount to withdraw");

        balances[msg.sender] = balances[msg.sender].sub(_amount);

        require(l1Token.transfer(msg.sender, _amount), "Could not transfer tokens.");
        emit Withdraw(msg.sender, _amount);
    }
}
