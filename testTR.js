

const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()
const fs = require("fs")
const RLP = require('rlp')
const util = require('ethereumjs-util')
const txProof = require("./txProof")
const EthereumTx = require('ethereumjs-tx')

function tx2rlp(tx) {
    const signedSiblingTx = new EthereumTx(squanchTx(tx))
    return signedSiblingTx.serialize()
}

function tx2rlp(tx) {
    const signedSiblingTx = new EthereumTx(squanchTx(tx))
    console.log(signedSiblingTx)
    return "0x" + Buffer.from(RLP.encode(signedSiblingTx.raw)).toString("hex")
}

function squanchTx(tx) {
    console.log(tx)
    tx.gas = '0x' + parseInt(tx.gas).toString(16)
    tx.gasPrice = '0x' + parseInt(tx.gasPrice).toString(16)
    tx.value = '0x' + parseInt(tx.value).toString(16) || '0'
    tx.data = tx.input
    return tx
}

var host = process.argv[2] || "localhost"

// web3.setProvider(new web3.providers.WebsocketProvider('ws://' + host + ':8546'))
web3.setProvider(new web3.providers.HttpProvider('http://' + host + ':8545'))

const dir = "./compiled/"

var send_opt

async function createContract(name, args) {
    var code = "0x" + fs.readFileSync(dir + name + ".bin")
    var abi = JSON.parse(fs.readFileSync(dir + name + ".abi"))
    return new web3.eth.Contract(abi).deploy({data: code, arguments:args}).send(send_opt)
}

function hash(dta) {
    return util.sha3(Buffer.from(dta.substr(2),"hex"))
}

async function doDeploy() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    var store = await createContract("Blockchain")
    console.log("Contract at", store.options.address)
    var my_tx = await store.methods.storeHashes(20).send(send_opt)
    console.log("storing hashes", my_tx)
    
    var bnum = await web3.eth.getBlockNumber()
    var blk = await web3.eth.getBlock(bnum)
    var bheader = await web3.eth.getBlockHeader(blk.hash)
    console.log("current block", blk)
    console.log("Checking hash", hash(bheader))
    var tx = await store.methods.storeHashes(20).send(send_opt)
    console.log("storing hashes again", tx.status)

    var tx = await store.methods.storeHeader(bnum, bheader).send(send_opt)
    console.log("storing header", tx.status)

    /*
    var lst = await txProof.build(2, blk, web3)
    var proof_rlp = RLP.encode(lst)
    console.log("proof for transaction", lst, proof_rlp, "... its length is", proof_rlp.length)
    console.log("checking hash", util.sha3(RLP.encode(lst[0])), util.sha3(""))
    console.log(await store.methods.transactionDebug("0x"+util.sha3("").toString("hex"), 2, "0x"+proof_rlp.toString("hex"), bnum).call(send_opt))
    var tx = await store.methods.transactionInBlock("0x"+util.sha3("").toString("hex"), 2, "0x"+proof_rlp.toString("hex"), bnum).send(send_opt)
    console.log("Proving transaction in block", tx.status)
    */

    var lst = await txProof.build(my_tx.transactionIndex, blk, web3)
    var proof_rlp = RLP.encode(lst)
    console.log("proof for transaction", lst, proof_rlp, "... its length is", proof_rlp.length)
    console.log("checking hash", util.sha3(RLP.encode(lst[0])))
    console.log(await store.methods.transactionDebug(my_tx.transactionHash, my_tx.transactionIndex, "0x"+proof_rlp.toString("hex"), bnum).call(send_opt))
    var tx = await store.methods.transactionInBlock(my_tx.transactionHash, my_tx.transactionIndex, "0x"+proof_rlp.toString("hex"), bnum).send(send_opt)
    console.log("Proving transaction in block", tx.status)
    var my_tx2 = await web3.eth.getTransaction(blk.transactions[my_tx.transactionIndex])
    var tx_rlp = tx2rlp(my_tx2)
    var tx = await store.methods.storeTransaction(tx_rlp).send(send_opt)
    console.log("Adding transaction", tx.status, tx_rlp, hash(tx_rlp))
    console.log(await store.methods.trInfo("0x"+hash(tx_rlp).toString("hex")).call(send_opt))
    console.log(await store.methods.transactionSender(bnum, my_tx.transactionIndex).call(send_opt))
}

doDeploy()


