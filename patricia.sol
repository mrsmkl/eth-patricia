pragma solidity ^0.4.19;

contract Patricia {
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

    function readSize(bytes rlp, uint idx, uint len) internal pure returns (uint) {
        uint res = 0;
        for (uint i = 0; i < len; i++) res += 256*res + uint8(rlp[idx+i]);
        return res;
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
        while (jdx < len+idx) {
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
   
    function rlpFindBytes(bytes memory rlp, uint n) internal pure returns (bytes) {
        uint idx = 1;
        for (uint i = 0; i < n; i++) {
            idx += rlpByteSkipLength(rlp, idx);
        }
        uint len;
        uint szlen;
        (len, szlen) = rlpByteLength(rlp, idx);
        return sliceBytes(rlp, idx+szlen, len);
    }
   
    // unmangle HP encoding to boolean value and nibbles
    function unhp(bytes b) internal pure returns (bool tval, uint8[] res) {
        uint8 elem = uint8(b[0]);
        uint8 flag = elem/16;
        tval = (flag & 0x2 == 1);
        bool even = (flag & 0x1 == 0);
        uint len = ((b.length-1) / 2) + (even ? 0 : 1);
        res = new uint8[](len);
        uint idx = 0;
        if (!even) {
            idx = 1;
            res[0] = elem&0xf;
        }
        for (uint i = 1; i < b.length; i++) {
            uint8 elem1 = uint8(b[i]);
            res[idx+i*2] = (elem1 / 16) & 15;
            res[idx+i*2+1] = elem1 & 15;
        }
    }
   
    function matchingNibbleLength(uint8[] a, uint8[] b) internal pure returns (uint) {
        uint len = a.length > b.length ? b.length : a.length;
        for (uint i = 0; i < len; i++) {
            if (a[i] != b[i]) return i;
        }
        return i;
    }
   
    enum State {
        UNFINISHED,
        NOTFOUND,
        FOUND
    }
   
    uint8[] key;
    bytes32 wantHash;
   
    State state;
    bytes found;

    function init(bytes _key, bytes32 root) public {
        key = bytesToNibbles(_key);
        wantHash = root;
    }
    
    function stepProof(bytes p) public {
        require(state == State.UNFINISHED);
        require(wantHash == keccak256(p));
        // The key cannot be found here
        if (p.length == 0) {
            state = State.NOTFOUND;
            return;
        }
        // Branch
        // p[0] == 192+17 == 209
        if (rlpArrayLength(p,0) == 17) {
            if (key.length == 0) {
                found = rlpFindBytes(p, 16);
                state = State.FOUND;
            }
            else {
                bytes memory child = rlpFindBytes(p, uint(uint8(key[0])));
                key = slice(key, 1, key.length-1);
                if (child.length == 32) wantHash = bytesToBytes32(child);
                else wantHash = keccak256(child);
            }
        }
        // Leaf or extension
        // p[0] == 194
        else if (rlpArrayLength(p,0) == 2) {
            bool kind;
            uint8[] memory nibbles;
            (kind, nibbles) = unhp(rlpFindBytes(p, 0));
            // seems like the kind can be ignored
            uint mlen = matchingNibbleLength(nibbles, key);
            if (mlen != nibbles.length) {
                state = State.NOTFOUND;
                return;
            }
            bytes memory child2 = rlpFindBytes(p, 1);
            key = slice(key, mlen, key.length-mlen);
            if (key.length == 0) {
                found = child2;
                state = State.FOUND;
            }
            else {
                wantHash = bytesToBytes32(child2);
            }
        }
        // Bad node
        else {
            revert();
        }
    }
    
    function debug() public view returns (bytes32, uint8[], bytes) {
        return (wantHash, key, found);
    }

}
