pragma solidity ^0.4.18;

import './custom.sol';
import './store.sol';

contract GetStorage is GenericCustom {
    Blockchain store;
    function GetStorage(Blockchain s) public {
        store = s;
    }
    function work(bytes32[] arr) public returns (bytes32) {
        return store.accountStorage(uint(arr[0]), address(arr[1]), bytes32(arr[2]));
    }
}

