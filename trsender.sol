pragma solidity ^0.4.18;

import './custom.sol';
import './store.sol';

contract TrSender is GenericCustom {
    Blockchain store;
    function TrSender(Blockchain s) public {
        store = s;
    }
    function work(bytes32[] arr) public returns (bytes32) {
        return bytes32(store.transactionSender(uint(arr[0]), uint(arr[1])));
    }
}

