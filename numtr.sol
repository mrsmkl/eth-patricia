pragma solidity ^0.4.18;

import './custom.sol';
import './store.sol';

contract NumTr is GenericCustom {
    Blockchain store;
    function NumTr(Blockchain s) public {
        store = s;
    }
    function work(bytes32[] arr) public returns (bytes32) {
        return bytes32(store.blockTransactions(uint(arr[0])));
    }
}

