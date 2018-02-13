pragma solidity ^0.4.19;

contract Transaction {
    
    function readSize(bytes rlp, uint idx, uint len) public pure returns (uint) {
        uint res = 0;
        for (uint i = 0; i < len; i++) res += 256*res + uint8(rlp[idx+i]);
        return res;
    }
    
    function readInteger(bytes rlp) public pure returns (uint) {
        if (rlp.length == 0) return 0;
        uint8 elem = uint8(rlp[0]);
        if (elem < 128) return elem;
        return readSize(rlp, 1, elem-128);
    }
    
    // length in bytes of the RLP element starting at position idx
    function rlpByteLength(bytes rlp, uint idx) public pure returns (uint, uint) {
        uint8 elem = uint8(rlp[idx]);
        if (elem < 128) return (1, 0);
        if (elem == 128) return (0, 1);
        if (elem >= 247) {
            return (readSize(rlp, idx+1, elem-247), elem-247+1);
        }
        if (elem >= 192) {
            return (elem - 192, 1);
        }
        if (elem >= 183) {
            return (readSize(rlp, idx+1, elem-183), elem-183+1);
        }
        return (elem - 128, 1);
    }

    function rlpSizeLength(bytes rlp, uint idx) public pure returns (uint) {
        uint8 elem = uint8(rlp[idx]);
        if (elem < 128) return 0;
        if (elem == 128) return 1;
        if (elem >= 247) {
            return elem-247+1;
        }
        if (elem >= 192) {
            return 1;
        }
        if (elem >= 183) {
            return elem-183+1;
        }
        return 1;
    }

    // length in bytes of the RLP element starting at position idx
    function rlpByteSkipLength(bytes rlp, uint idx) public pure returns (uint) {
        uint8 elem = uint8(rlp[idx]);
        if (elem < 128) return 1;
        if (elem == 128) return 1;
        if (elem >= 247) {
            return (readSize(rlp, idx+1, elem-247) + elem-247+1);
        }
        if (elem >= 192) {
            return (elem - 192 + 1);
        }
        if (elem >= 183) {
            return (readSize(rlp, idx+1, elem-183) + elem-183+1);
        }
        return (elem - 128 + 1);
    }

    // how many elements in an RLP array
    function rlpArrayLength(bytes rlp, uint idx) public pure returns (uint) {
        uint len;
        uint szlen;
        (len, szlen) = rlpByteLength(rlp, idx);
        if (len == 0) return 0;
        uint jdx = idx+szlen;
        uint res = 0;
        while (jdx < len+idx+szlen) {
            jdx += rlpByteSkipLength(rlp, jdx);
            res++;
        }
        return res;
    }
    
    function sliceBytes(bytes b, uint idx, uint len) internal pure returns (bytes) {
        bytes memory res = new bytes(len);
        for (uint i = 0; i < len; i++) res[i] = b[idx+i];
        return res;
    }

    function slice(uint8[] storage b, uint idx, uint len) internal view returns (uint8[]) {
        uint8[] memory res = new uint8[](len);
        for (uint i = 0; i < len; i++) res[i] = b[idx+i];
        return res;
    }

    function rlpFindBytes(bytes memory rlp, uint n) public pure returns (bytes) {
        uint idx = rlpSizeLength(rlp, 0);
        for (uint i = 0; i < n; i++) {
            idx += rlpByteSkipLength(rlp, idx);
        }
        return sliceBytes(rlp, idx, rlpByteSkipLength(rlp, idx));
    }
    
    function integerLength(uint n) public pure returns (uint8) {
        uint8 res = 0;
        while (n != 0) {
            n = n/256;
            res++;
        }
        return res;
    }
    
    function arrayPrefix(uint len) public pure returns (bytes) {
        if (len < 56) {
            bytes memory res = new bytes(1);
            res[0] = byte(len-192);
        }
        else {
            uint ilen = integerLength(len);
            bytes memory res2 = new bytes(1+ilen);
            res2[0] = byte(247+ilen);
            for (uint i = 1; i < ilen; i++) {
                res2[ilen-i] = byte(len&0xff);
                len = len/256;
            }
            return res2;
        }
    }
    
    function checkHash(bytes32 hash, bytes tr) public pure returns (address) {
        // w
        uint v = readInteger(rlpFindBytes(tr, 6));
        // r
        uint r = readInteger(rlpFindBytes(tr, 7));
        // s
        uint s = readInteger(rlpFindBytes(tr, 8));
        return ecrecover(hash, uint8(v), bytes32(r), bytes32(s));
    }

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

