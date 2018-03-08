pragma solidity ^0.4.18;

contract Vote {
    function yes() public pure {}
    function no() public pure {}
    
    function setBalance(uint b) public {
        bytes32 addr = bytes32(msg.sender);
        assembly {
            sstore(addr, b)
        }
    }
    
}

