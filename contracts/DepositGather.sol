// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GLDToken is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Gold", "GLD") {
        _mint(msg.sender, initialSupply);
    }
}

contract DeployGathererExecutor {
    function executeDeployGatherer(
        bytes32 salt,
        address payable erc20
    ) external {
        new DeployGatherer{salt: salt}(erc20);
    }

    function getAddress(
        bytes32 salt,
        address payable erc20
    ) external view returns (address) {
        bytes memory args = abi.encode(erc20);
        bytes memory deployed = abi.encodePacked(
            type(DeployGatherer).creationCode,
            args
        );
        return Create2.computeAddress(salt, keccak256(deployed));
    }
}

contract DeployGatherer {
    using SafeERC20 for IERC20;

    constructor(address payable addr) public {
        IERC20 instance = IERC20(addr);
        address payable toAddr = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;
        uint256 forwarderBalance = instance.balanceOf(address(this));
        if (forwarderBalance > 0) {
            instance.safeTransfer(toAddr, forwarderBalance);
        }
        selfdestruct(address(0x0));
    }
}
