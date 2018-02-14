pragma solidity ^0.4.19;

import './util.sol';

// Contract for mirroring needed parts of the blockchain
contract Blockchain is Util {

    mapping (uint => bytes32) block_hash;

    struct BlockData {
        bytes32 stateRoot;
        bytes32 transactionRoot;
        mapping (uint => bytes32) transactions; // element 1 means not found
        mapping (address => bytes32) accounts;  // element 1 means not found
    }
    
    mapping (bytes32 => BlockData) block_data;

    struct TransactionData {
        address to;
        address sender;
        bytes data;
    }
    
    mapping (bytes32 => TransactionData) transactions;
    
    struct AccountData {
        bytes32 storageRoot;
        mapping (bytes32 => bytes32) stuff;
        mapping (bytes32 => bool) stuff_checked;
    }

    mapping (bytes32 => AccountData) accounts;

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

    function getAddress(bytes rlp) internal pure returns (address) {
        if (rlp.length == 0) return 0;
        require(rlp.length == 21);
        return address(readSize(rlp, 1, 20));
    }

    function storeHeader(uint n, bytes header) public {
        // sanity check
        require(rlpArrayLength(header, 0) == 15);
        require(keccak256(header) == block_hash[n]);
        BlockData storage dta = block_data[block_hash[n]];
        dta.stateRoot = getBytes32(rlpFindBytes(header, 3));
        dta.transactionRoot = getBytes32(rlpFindBytes(header, 4));
    }

    function transactionSender(bytes32 hash, bytes tr) public pure returns (address) {
        // w
        uint v = readInteger(rlpFindBytes(tr, 6));
        // r
        uint r = readInteger(rlpFindBytes(tr, 7));
        // s
        uint s = readInteger(rlpFindBytes(tr, 8));
        return ecrecover(hash, uint8(v), bytes32(r), bytes32(s));
    }

    function storeTransaction(bytes tr) public {
        // read all the fields of transaction
        require(rlpArrayLength(tr, 0) == 9);
        bytes[] memory d = new bytes[](6);
        d[0] = rlpFindBytes(tr, 0); // nonce
        d[1] = rlpFindBytes(tr, 1); // price
        d[2] = rlpFindBytes(tr, 2); // gas
        d[3] = rlpFindBytes(tr, 3); // to
        d[4] = rlpFindBytes(tr, 4); // value
        d[5] = rlpFindBytes(tr, 5); // data
        
        uint len = d[0].length + d[1].length + d[2].length + d[3].length + d[4].length + d[5].length;
        bytes32 hash = keccak256(arrayPrefix(len+3), d[0], d[1], d[2], d[3], d[4], d[5], byte(0x1c), bytes2(0x8080));
        TransactionData storage tr_data = transactions[keccak256(tr)];
        tr_data.sender = transactionSender(hash, tr);
        tr_data.to = getAddress(d[3]);
        tr_data.data = d[5]; // probably should remove RLP prefix
    }

    function storeAccount(bytes rlp) public {
        // read all the fields of account
        require(rlpArrayLength(rlp, 0) == 4);
        AccountData storage a_data = accounts[keccak256(rlp)];
        // 0 nonce
        // 1 balance
        // 2 storage
        // 3 code
        a_data.storageRoot = getBytes32(rlpFindBytes(rlp, 2));
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
        address owner;
        Kind kind;
        bytes32 root;
        uint tr;        // tr number
        bytes32 ptr;    // storage pointer
        address addr;   // account address
    }
    
    mapping (bytes32 => Session) sessions;
    
    function initTransaction(uint blk, uint n) public {
        Session storage s = sessions[keccak256(msg.sender, blk, n)];
        s.owner = msg.sender;
        s.key = bytesToNibbles(rlpInteger(n));
        s.kind = Kind.TRANSACTION;
        s.root = block_hash[blk];
        s.wantHash = block_data[s.root].transactionRoot;
        s.tr = n;
    }

    function initAccount(uint blk, address addr) public {
        Session storage s = sessions[keccak256(msg.sender, blk, addr)];
        s.owner = msg.sender;
        s.key = bytesToNibbles(bytes32ToBytes(keccak256(addr)));
        s.kind = Kind.ACCOUNT;
        s.root = block_hash[blk];
        s.wantHash = block_data[s.root].stateRoot;
        s.addr = addr;
    }

    function initStorage(bytes32 acct, bytes32 ptr) public {
        Session storage s = sessions[keccak256(msg.sender, acct, ptr)];
        s.owner = msg.sender;
        s.key = bytesToNibbles(bytes32ToBytes(keccak256(ptr)));
        s.kind = Kind.STORAGE;
        s.root = acct;
        s.wantHash = accounts[acct].storageRoot;
        s.ptr = ptr;
    }
    
    function sessionNotFound(bytes32 id) internal {
        Session storage s = sessions[id];
        s.state = State.NOTFOUND;
        if (s.kind == Kind.TRANSACTION) {
            block_data[s.root].transactions[s.tr] = bytes32(uint(1));
        }
        else if (s.kind == Kind.ACCOUNT) {
            block_data[s.root].accounts[s.addr] = bytes32(uint(1));
        }
        else if (s.kind == Kind.STORAGE) {
            accounts[s.root].stuff_checked[s.ptr] = true;
        }
    }

    function sessionFound(bytes32 id, bytes found) internal {
        Session storage s = sessions[id];
        s.state = State.FOUND;
        if (s.kind == Kind.TRANSACTION) {
            block_data[s.root].transactions[s.tr] = getBytes32(found);
        }
        else if (s.kind == Kind.ACCOUNT) {
            block_data[s.root].accounts[s.addr] = getBytes32(found);
        }
        else if (s.kind == Kind.STORAGE) {
            accounts[s.root].stuff[s.ptr] = getBytes32(found);
            accounts[s.root].stuff_checked[s.ptr] = true;
        }
    }

    function stepProof(bytes32 id, bytes p) public {
        Session storage s = sessions[id];
        require(s.owner == msg.sender);
        require(s.state == State.UNFINISHED);
        require(s.wantHash == keccak256(p));
        // The key cannot be found here
        if (p.length == 0) {
            sessionNotFound(id);
            return;
        }
        // Branch
        // p[0] == 192+17 == 209
        if (rlpArrayLength(p,0) == 17) {
            if (s.key.length == 0) {
                sessionFound(id, rlpFindBytes(p, 16));
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
                sessionNotFound(id);
                return;
            }
            bytes memory child2 = rlpFindBytes(p, 1);
            s.key = slice(s.key, mlen, s.key.length-mlen);
            if (s.key.length == 0) {
                sessionFound(id, child2);
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


