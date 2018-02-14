#!/bin/sh

solc --abi --optimize --overwrite --bin -o compiled patricia.sol
solc --abi --optimize --overwrite --bin -o compiled transaction.sol
solc --abi --optimize --overwrite --bin -o compiled account.sol
solc --abi --optimize --overwrite --bin -o compiled blockchain.sol

