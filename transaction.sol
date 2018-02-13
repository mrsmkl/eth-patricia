pragma solidity ^0.4.19;
// pragma experimental ABIEncoderV2;

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
    function check(bytes tr) public pure returns (address, address, bytes32, bytes,
    bytes) {
        // read all the fields of transaction
        require(rlpArrayLength(tr, 0) == 9);
        bytes[] memory d = new bytes[](6);
        d[0] = rlpFindBytes(tr, 0);
        d[1] = rlpFindBytes(tr, 1);
        d[2] = rlpFindBytes(tr, 2);
        d[3] = rlpFindBytes(tr, 3);
        d[4] = rlpFindBytes(tr, 4);
        d[5] = rlpFindBytes(tr, 5);
        /*
        // nonce
        bytes memory nonce_bytes = rlpFindBytes(tr, 0);
        // gasprice
        bytes memory price_bytes = rlpFindBytes(tr, 1);
        // gas
        bytes memory gas_bytes = rlpFindBytes(tr, 2);
        // to
        bytes memory to_bytes = rlpFindBytes(tr, 3);
        // value
        bytes memory value_bytes = rlpFindBytes(tr, 4);
        // data
        bytes memory data_bytes = rlpFindBytes(tr, 5);
        */
        require(d[3].length == 21);
        address to = address(readSize(d[3], 1, 20));
        uint len = d[0].length + d[1].length + d[2].length + d[3].length + d[4].length + d[5].length;
        bytes32 hash = keccak256(arrayPrefix(len+3), d[0], d[1], d[2], d[3], d[4], d[5], byte(0x1c), bytes2(0x8080));
        address from = checkHash(hash, tr);
        return (from, to, hash, arrayPrefix(len+3), d[0]);
    }
}

