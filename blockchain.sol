pragma solidity ^0.4.19;

import './util.sol';

contract Blockchain is Util {

    mapping (uint => bytes32) block_hash;

    struct BlockData {
        bytes32 stateRoot;
        bytes32 transactionRoot;
        mapping (uint => bytes32) transactions;
        mapping (address => bytes32) accounts;
    }

    mapping (bytes32 => BlockData) block_data;

    function storeHashes(uint n) public {
        for (uint i = 1; i <= n; i++) block_hash[block.number-i] = block.blockhash(block.number-i);
    }

    function getBytes32(bytes rlp) internal pure returns (bytes32) {
        require(rlp.length == 33);
        bytes32 res;
        assembly {
            res := mload(add(33,rlp))
        }
        return res;
    }

    function storeHeader(uint n, bytes header) public {
        // sanity check
        require(rlpArrayLength(header, 0) == 15);
        require(keccak256(header) == block_hash[n]);
        BlockData storage dta = block_data[block_hash[n]];
        dta.stateRoot = getBytes32(rlpFindBytes(header, 3));
        dta.transactionRoot = getBytes32(rlpFindBytes(header, 4));
    }

    enum State {
        UNFINISHED,
        NOTFOUND,
        FOUND
    }
    
    enum Kind {
        TRANSACTION,
        ACCOUNT,
        STORAGE
    }

    struct Session {
        uint8[] key;    
        bytes32 wantHash;
        State state;
        bytes found;
        address owner;
        uint block;
        Kind kind;
        uint tr;
        address addr;
        bytes32 storage_addr;
    }
    
    mapping (bytes32 => Session) sessions;

    function init(bytes key, bytes32 root) public {
        Session storage s = sessions[keccak256(msg.sender, key, root)];
        s.key = bytesToNibbles(key);
        s.wantHash = root;
        s.owner = msg.sender;
    }
    
    function stepProof(bytes32 id, bytes p) public {
        Session storage s = sessions[id];
        require(s.state == State.UNFINISHED);
        require(s.wantHash == keccak256(p));
        // The key cannot be found here
        if (p.length == 0) {
            s.state = State.NOTFOUND;
            return;
        }
        // Branch
        // p[0] == 192+17 == 209
        if (rlpArrayLength(p,0) == 17) {
            if (s.key.length == 0) {
                s.found = rlpFindBytes(p, 16);
                s.state = State.FOUND;
            }
            else {
                bytes memory child = rlpFindBytes(p, uint(uint8(s.key[0])));
                s.key = slice(s.key, 1, s.key.length-1);
                if (child.length == 33) {
                    child = sliceBytes(child,1,32);
                    s.wantHash = bytesToBytes32(child);
                }
                else s.wantHash = keccak256(child);
            }
        }
        // Leaf or extension
        // p[0] == 194
        else if (rlpArrayLength(p,0) == 2) {
            bool kind;
            uint8[] memory nibbles;
            (kind, nibbles) = unhp(rlpFindBytes(p, 0));
            // seems like the kind can be ignored
            uint mlen = matchingNibbleLength(nibbles, s.key);
            if (mlen != nibbles.length) {
                s.state = State.NOTFOUND;
                return;
            }
            bytes memory child2 = rlpFindBytes(p, 1);
            s.key = slice(s.key, mlen, s.key.length-mlen);
            if (s.key.length == 0) {
                s.found = child2;
                s.state = State.FOUND;
            }
            else {
                if (child2.length == 33) {
                    child2 = sliceBytes(child2,1,32);
                    s.wantHash = bytesToBytes32(child2);
                }
                else s.wantHash = keccak256(child2);
            }
        }
        // Bad node
        else {
            revert();
        }
    }

    
}


