pragma solidity ^0.4.19;

import 'util.sol';

contract Transaction is Util {
    
    function checkHash(bytes32 hash, bytes tr) public pure returns (address) {
        // w
        uint v = readInteger(rlpFindBytes(tr, 6));
        // r
        uint r = readInteger(rlpFindBytes(tr, 7));
        // s
        uint s = readInteger(rlpFindBytes(tr, 8));
        return ecrecover(hash, uint8(v), bytes32(r), bytes32(s));
    }

    // perhaps these are just concatenated without RLP
    function check(bytes tr) public pure {
        // read all the fields of transaction
        require(rlpArrayLength(tr, 0) == 9);
        // nonce
        bytes memory nonce_bytes = rlpFindBytes(tr, 0);
        // gasprice
        bytes memory price_bytes = rlpFindBytes(tr, 1);
        // gas
        bytes memory gas_bytes = rlpFindBytes(tr, 2);
        // to
        bytes memory to_bytes = rlpFindBytes(tr, 3);
        require(to_bytes.length == 21);
        address to = address(readSize(to_bytes, 1, 20));
        // value
        bytes memory value_bytes = rlpFindBytes(tr, 4);
        // data
        bytes memory data_bytes = rlpFindBytes(tr, 5);
        uint len = nonce_bytes.length + price_bytes.length + gas_bytes.length + to_bytes.length + value_bytes.length + data_bytes.length;
        bytes32 hash = keccak256(arrayPrefix(len), nonce_bytes, price_bytes, gas_bytes, to_bytes, value_bytes, data_bytes);
        address from = checkHash(hash, tr);
    }
}

