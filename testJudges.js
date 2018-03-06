

const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()
const fs = require("fs")
const RLP = require('rlp')
const util = require('ethereumjs-util')
const txProof = require("./txProof")
const EthereumTx = require('ethereumjs-tx')

const mongoose = require('mongoose')
mongoose.connect('mongodb://localhost/truebit')

const File = mongoose.model('File', { root: String, data: String })

var host = process.argv[2] || "localhost"

var config = JSON.parse(fs.readFileSync("config.json"))

web3.setProvider(new web3.providers.WebsocketProvider('ws://' + host + ':8546'))
// web3.setProvider(new web3.providers.HttpProvider('http://' + host + ':8545'))

const dir = "./compiled/"

var send_opt

function createContract(name, addr) {
    var abi = JSON.parse(fs.readFileSync(dir + name + ".abi"))
    return new web3.eth.Contract(abi, addr)
}

function hash(dta) {
    return util.sha3(Buffer.from(dta.substr(2),"hex"))
}

function make32(str) {
    if (typeof str == "number") str = str.toString(16)
    if (str.substr(0,2) == "0x") str = str.substr(2)
    while (str.length < 64) str = "0"+str;
    return str
}

function conv(str) {
    return "0x" + make32(str)
}

function tx2rlp(tx) {
    const signedSiblingTx = new EthereumTx(squanchTx(tx))
    console.log(signedSiblingTx)
    return "0x" + Buffer.from(RLP.encode(signedSiblingTx.raw)).toString("hex")
}

function squanchTx(tx) {
  tx.gas = '0x' + parseInt(tx.gas).toString(16);
  tx.gasPrice = '0x' + parseInt(tx.gasPrice).toString(16);
  tx.value = '0x' + parseInt(tx.value).toString(16) || '0';
  tx.data = tx.input;
  return tx;
}

function hex2rlp(str) {
    return "0x"+RLP.encode(Buffer.from(str, "hex")).toString("hex")
}

function storeHash(root, data) {
    var file = new File({root: root, data: data})
    return file.save()
}

async function readData(hash) {
    var asd = await File.find({root: hash})
    var lst = []
    var str = asd[0].data
    console.log(str)
    for (var i = 0; i < str.length; i += 64) lst.push(str.substr(i, 64))
    return lst
}

async function merkle(c, lst) {
    var res = await c.methods.dataMerkle(lst.map(conv), 0, 2).call()
    var data = lst.map(make32).join("")
    storeHash(res, data)
    return res
}

async function handleNumTr(err, ev) {
    if (err) return console.log("handle num tr", err)
    var id = ev.returnValues.id
    var root = ev.returnValues.state
    var solver = ev.returnValues.solver
}

var store

async function handleTrSender(err, ev) {
    if (err) return console.log("handle tr sender", err)
    var id = ev.returnValues.id
    var root = ev.returnValues.state
    var solver = ev.returnValues.solver
    
    var data = await readData(root)
    
    var bnum = parseInt("0x"+data[0])
    var trnum = parseInt("0x"+data[1])
    
    console.log("Event at tr sender", ev.returnValues, bnum, trnum)
    
    
    // generate proof
    var blk = await web3.eth.getBlock(bnum)
    var bheader = await web3.eth.getBlockHeader(blk.hash)
    var tx = store.methods.storeHeader(bnum, bheader).send(send_opt)
    console.log("storing header")
    
    setTimeout(async () => console.log(await store.methods.blockData(bnum).call(send_opt)), 1000)
    
    var my_tx = await web3.eth.getTransaction(blk.transactions[trnum])
    console.log(my_tx)
    var lst = await txProof.build(my_tx.transactionIndex, blk, web3)
    var proof_rlp = RLP.encode(lst)
    console.log("proof for transaction", lst, proof_rlp, "... its length is", proof_rlp.length)
    console.log("checking hash", util.sha3(RLP.encode(lst[0])))
    console.log(await store.methods.transactionDebug(my_tx.hash, my_tx.transactionIndex, "0x"+proof_rlp.toString("hex"), bnum).call(send_opt))
    var tx = store.methods.transactionInBlock(my_tx.hash, my_tx.transactionIndex, "0x"+proof_rlp.toString("hex"), bnum).send(send_opt)
    var tx_rlp = tx2rlp(my_tx)
    store.methods.storeTransaction(tx_rlp).send(send_opt)
    // console.log("Proving transaction in block", tx.status)
    console.log("geth websockets won't work", tx_rlp)
    
    // did it work?
    setTimeout(async () => {
        console.log(await store.methods.trInfo("0x"+hash(tx_rlp).toString("hex")).call(send_opt))
        console.log(await store.methods.transactionSender(bnum, trnum).call(send_opt))
    }, 1000)
}

async function handleTrReceiver(err, ev) {
    if (err) return console.log("handle tr recv", err)
    var id = ev.returnValues.id
    var root = ev.returnValues.state
    var solver = ev.returnValues.solver
}

async function handleTrData(err, ev) {
    if (err) return console.log("handle tr data", err)
    var id = ev.returnValues.id
    var root = ev.returnValues.state
    var solver = ev.returnValues.solver
}

async function handleGetStorage(err, ev) {
    if (err) return console.log("handle storage", err)
    var id = ev.returnValues.id
    var root = ev.returnValues.state
    var solver = ev.returnValues.solver
}

async function testSender(trsender) {
    var bnum = await web3.eth.getBlockNumber()
    var my_tx = store.methods.storeHashes(20).send(send_opt)
    // console.log(my_tx.status)
    var lst = [bnum-10, 0]
    var root = await merkle(trsender, lst)
    console.log("Root", root)
    
    trsender.methods.init(root, 0, 0, send_opt.from, send_opt.from).send(send_opt)
}

async function main() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    console.log("Using account", accts[0])
    store = createContract("Blockchain", config.store)
    var numtr = createContract("NumTr", config.numtr)
    var trsender = createContract("TrSender", config.trsender)
    var trreceiver = createContract("TrReceiver", config.trsender)
    var trdata = createContract("TrData", config.trreceiver)
    var getstorage = createContract("GetStorage", config.getstorage)

    numtr.events.AddedObligation(handleNumTr)
    trsender.events.AddedObligation(handleTrSender)
    trreceiver.events.AddedObligation(handleTrReceiver)
    trdata.events.AddedObligation(handleTrData)
    getstorage.events.AddedObligation(handleGetStorage)
    
    console.log("Listening events")
    await testSender(trsender)
}

main()
