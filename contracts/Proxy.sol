// A solidity implementation of the minimal proxy deployed from ExchangeDeposit
contract Proxy {
    address payable public immutable target;

    constructor(address payable tgt) public {
        require(tgt != address(0), "0x0 is an invalid address");
        target = tgt;
    }

    function getProxyTarget() internal view returns (address payable) {
        return target;
    }

    // if calldatasize == 0, call to target
    receive() external payable {
        (bool ok, bytes memory ret) = target.call{value: msg.value}("");
        assembly {
            switch ok
            case 0 {
                revert(add(ret, 0x20), mload(ret))
            }
            default {
                return(add(ret, 0x20), mload(ret))
            }
        }
    }

    // delegatecall to target with calldata
    fallback() external payable {
        (bool ok, bytes memory ret) = target.delegatecall(msg.data);
        assembly {
            switch ok
            case 0 {
                revert(add(ret, 0x20), mload(ret))
            }
            default {
                return(add(ret, 0x20), mload(ret))
            }
        }
    }
}
