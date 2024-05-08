// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GLDToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Gold", "GLD") {
        _mint(msg.sender, initialSupply);
    }
}

contract DeterministicProxyCloner {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error InsufficientBalance(uint256 balance, uint256 needed);

    /**
     * @dev The deployment failed.
     */
    error FailedDeployment();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function clone(
        address implementation,
        bytes32 salt
    ) internal returns (address instance) {
        return clone(implementation, salt, 0);
    }

    /**
     * @dev Same as {xref-Clones-cloneDeterministic-address-bytes32-}[cloneDeterministic], but with
     * a `value` parameter to send native currency to the new contract.
     *
     * NOTE: Using a non-zero value at creation will require the contract using this function (e.g. a factory)
     * to always have enough balance for new deployments. Consider exposing this function under a payable method.
     */
    function clone(
        address implementation,
        bytes32 salt,
        uint256 value
    ) internal returns (address instance) {
        if (address(this).balance < value) {
            revert InsufficientBalance(address(this).balance, value);
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Stores the bytecode after address
            mstore(0x20, 0x5af43d82803e903d91602b57fd5bf3)
            // implementation address
            mstore(0x11, implementation)
            // Packs the first 3 bytes of the `implementation` address with the bytecode before the address.
            mstore(
                0x00,
                or(
                    shr(0x88, implementation),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
            instance := create2(value, 0x09, 0x37, salt)
        }
        if (instance == address(0)) {
            revert FailedDeployment();
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := and(
                keccak256(add(ptr, 0x43), 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictAddress(implementation, salt, address(this));
    }
}

contract Proxy {
    using SafeERC20 for IERC20;

    /**
     * @notice Execute a token transfer of the full balance from the proxy
     * to the designated recipient.
     * @param addr The address of the erc20 token contract
     */
    function gatherErc20(address payable addr) public {
        IERC20 instance = IERC20(addr);
        address payable toAddr = payable(
            0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB
        );
        uint256 forwarderBalance = instance.balanceOf(address(this));
        if (forwarderBalance > 0) {
            instance.safeTransfer(toAddr, forwarderBalance);
        }
    }
}
