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
   
   function rlpArrayLength(bytes rlp) internal pure returns (int) {
      uint8 elem = uint8(rlp[0]);
      if (elem < 192 || elem >= 247) return -1;
      else return elem - 192;
   }
   
   function rlpByteLength(bytes rlp, uint idx) internal pure returns (int) {
      uint8 elem = uint8(rlp[idx]);
      if (elem < 128) return 1;
      if (elem >= 183) return -1;
      else return elem - 128;
   }
   
   function sliceBytes(bytes b, uint idx, uint len) internal returns (bytes) {
       
   }
   
   function rlpFindBytes(bytes rlp, int n) internal returns (bytes) {
      uint idx = 1;
      for (uint i = 0; i < n-1; i++) {
         int len = rlpByteLength(rlp, idx);
         require (len >= 0);
         idx += len + 1;
      }
      int len = rlpByteLength(rlp, idx);
      require (len >= 0);
      return sliceBytes(rlp, idx, len);
   }
   
   function stepProof(bytes p) public {
      require(wantHash == keccak256(p));
      // The key cannot be found here
      if (p.length == 0) {
         wantHash = 0;
         state = NOTFOUND;
         return;
      }
      // Branch
      // p[0] == 192+17 == 209
      if (rlpArrayLength(p) == 17) {
         if (key.length == 0) {
           bytes res = rlpFindBytes(16);
         }
      }
      // Leaf or extension
      // p[0] == 194
      else if (rlpArrayLength(p) == 2) {
      }
      // Bad node
      else {
         revert();
      }
   }
   
}
