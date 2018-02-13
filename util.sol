pragma solidity ^0.4.19;

contract Util {
    
    function bytesToNibbles(bytes str) internal pure returns (uint8[]) {
        uint8[] memory res = new uint8[](str.length*2);
        for (uint i = 0; i < str.length; i++) {
            uint8 elem = uint8(str[i]);
            res[i*2] = (elem / 16) & 15;
            res[i*2+1] = elem & 15;
        }
        return res;
    }
    
    function bytesToBytes32(bytes rlp) internal pure returns (bytes32) {
        bytes32 res;
        assembly {
            res := mload(add(32,rlp))
        }
        return res;
    }
    
    function readSize(bytes rlp, uint idx, uint len) public pure returns (uint) {
        uint res = 0;
        for (uint i = 0; i < len; i++) res = 256*res + uint8(rlp[idx+i]);
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
            res[0] = byte(len+192);
            return res;
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
}


