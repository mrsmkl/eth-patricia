pragma solidity ^0.4.18;

import './custom.sol';
import './store.sol';

contract TrData is GenericCustom {
    Blockchain store;
    function TrData(Blockchain s) public {
        store = s;
    }
    function work(bytes32[] arr) public returns (bytes32) {
        return store.transactionData32(uint(arr[0]), uint(arr[1]));
    }
}

