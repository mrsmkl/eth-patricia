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
   
   function bytesToBytes32(bytes rlp) internal pure returns (bytes32) {
       bytes32 res;
       assembly {
           res := mload(add(32,rlp))
       }
       return res;
   }
   
   function rlpArrayLength(bytes rlp) internal pure returns (int) {
      uint8 elem = uint8(rlp[0]);
      if (elem < 192 || elem >= 247) return -1;
      else return elem - 192;
   }
   
   function rlpByteLength(bytes rlp, uint idx) internal pure returns (uint) {
      uint8 elem = uint8(rlp[idx]);
      if (elem < 128) return 1;
      if (elem >= 183) {
          /// umm this can be an array
          uint n = elem - 192;
          uint res = 1;
          for (uint i = 0; i < n; i++) {
              uint len = rlpByteLength(rlp, idx);
              idx += len + 1;
              res += len + 1;
          }
          return res;
      }
      else return elem - 128;
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
      for (uint i = 0; i < n-1; i++) {
         uint len = rlpByteLength(rlp, idx);
         require (len >= 0);
         idx += len + 1;
      }
      len = rlpByteLength(rlp, idx);
      require (len >= 0);
      return sliceBytes(rlp, idx, len);
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
      if (rlpArrayLength(p) == 17) {
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
      else if (rlpArrayLength(p) == 2) {
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

}
