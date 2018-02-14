pragma solidity ^0.4.19;

import './util.sol';

contract Patricia is Util {

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
    
    bytes debug_child;
    
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
                debug_child = child;
                key = slice(key, 1, key.length-1);
                if (child.length == 33) {
                    child = sliceBytes(child,1,32);
                    wantHash = bytesToBytes32(child);
                }
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
                debug_child = child2;
                if (child2.length == 33) {
                    child2 = sliceBytes(child2,1,32);
                    wantHash = bytesToBytes32(child2);
                }
                else wantHash = keccak256(child2);
            }
        }
        // Bad node
        else {
            revert();
        }
    }

    function debug() public view returns (bytes32, uint8[], bytes, bytes) {
        return (wantHash, key, found, debug_child);
    }

}
