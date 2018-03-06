#!/bin/sh

solc --abi --optimize --overwrite --bin -o compiled store.sol
solc --abi --optimize --overwrite --bin -o compiled numtr.sol
solc --abi --optimize --overwrite --bin -o compiled trreceiver.sol
solc --abi --optimize --overwrite --bin -o compiled trsender.sol
solc --abi --optimize --overwrite --bin -o compiled trdata.sol
solc --abi --optimize --overwrite --bin -o compiled getstorage.sol

em++ -s  NO_EXIT_RUNTIME=0 -std=c++11 -o vote.js -I ~/boost_1_66_0 info.cc vote.cc

# solc --abi --optimize --overwrite --bin -o compiled patricia.sol
# solc --abi --optimize --overwrite --bin -o compiled transaction.sol
# solc --abi --optimize --overwrite --bin -o compiled account.sol
# solc --abi --optimize --overwrite --bin -o compiled blockchain.sol

