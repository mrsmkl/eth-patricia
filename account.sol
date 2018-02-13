pragma solidity ^0.4.19;

import 'util.sol';

contract Account is Util {
    
    function check(bytes tr) public pure {
        // read all the fields of account
        require(rlpArrayLength(tr, 0) == 4);
        // nonce
        bytes memory nonce_bytes = rlpFindBytes(tr, 0);
        // balance
        bytes memory balance_bytes = rlpFindBytes(tr, 1);
        // storage
        bytes memory storage_bytes = rlpFindBytes(tr, 2);
        // code
        bytes memory code_bytes = rlpFindBytes(tr, 3);
    }

}
