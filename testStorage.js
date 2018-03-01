
const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()
const fs = require("fs")
const RLP = require('rlp')
const util = require('ethereumjs-util')
const txProof = require("./txProof")

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

function make32(str) {
    while (str.length < 64) str = "0"+str;
    return "0x"+str
}

function hex2rlp(str) {
    return "0x"+RLP.encode(Buffer.from(str, "hex")).toString("hex")
}

async function doDeploy() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    var store = await createContract("Blockchain")
    console.log("Contract at", store.options.address)
    var bnum = await web3.eth.getBlockNumber()
    var blk = await web3.eth.getBlock(bnum)
    var bheader = await web3.eth.getBlockHeader(blk.hash)
    console.log("current block", blk)
    console.log("Checking hash", hash(bheader))
    var tx = await store.methods.storeHashes(20).send(send_opt)
    console.log("storing hashes", tx.status)
    var acc_dta = await web3.eth.getAccountRLP(blk.hash, store.options.address)
    console.log("countract account state", RLP.decode(acc_dta))
    var tx = await store.methods.storeHeader(bnum, bheader).send(send_opt)
    console.log("storing header", tx.status)
    var info = await store.methods.blockData(bnum).call(send_opt)
    console.log("this is the info", info)
    var tx = await store.methods.storeAccount(acc_dta).send(send_opt)
    var ahash = hash(acc_dta)
    console.log("storing account", tx.status, ahash, util.sha3(ahash))
    var proof = await web3.eth.getAccountProof(blk.hash, "0x"+hash(store.options.address).toString("hex"))
    var proof_rlp = RLP.encode(proof.map(a => RLP.decode(a)))
    console.log("proof for account", proof.map(a => [RLP.decode(a), hash(a)]))
    // console.log("but is it here", RLP.decode(proof[proof.length-1]))
    console.log("account proof length", proof_rlp.length, ahash, "0x"+hash(store.options.address).toString("hex"))
    // console.log(await store.methods.accountDebug("0x"+ahash.toString("hex"), store.options.address, "0x"+proof_rlp.toString("hex"), bnum).call(send_opt))
    var tx = await store.methods.accountInBlock("0x"+ahash.toString("hex"), store.options.address, "0x"+proof_rlp.toString("hex"), bnum).send(send_opt)
    console.log("Proving account in block", tx.status)
    console.log(await store.methods.accountData(bnum, store.options.address).call(send_opt))
    
    var proof = await web3.eth.getStorageProof(blk.hash, store.options.address, "0x"+hash(make32("12000023000034000045000056")).toString("hex"))
    var proof_rlp = RLP.encode(proof.map(a => RLP.decode(a)))
    // var proof = await web3.eth.getStorageProof(blk.hash, "0x"+hash(store.options.address).toString("hex"), make32("12000023000034000045000056"))
    console.log("storage proof", proof.map(a => [RLP.decode(a), hash(a)]))
    console.log("cell as rlp", hex2rlp("999988887777666655554444333322221111"))
//    console.log(await store.methods.storageDebug("0x"+ahash.toString("hex"), hex2rlp("999988887777666655554444333322221111"), make32("12000023000034000045000056"), "0x"+proof_rlp.toString("hex")).call(send_opt))
    var tx = await store.methods.storageInAccount("0x"+ahash.toString("hex"), hex2rlp("999988887777666655554444333322221111"), make32("12000023000034000045000056"), "0x"+proof_rlp.toString("hex")).send(send_opt)
    console.log("Proving storage of account in block", tx.status)
}

doDeploy()
