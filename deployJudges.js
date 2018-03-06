
const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()
const fs = require("fs")
const RLP = require('rlp')
const util = require('ethereumjs-util')
const txProof = require("./txProof")

const mongoose = require('mongoose')
mongoose.connect('mongodb://localhost/truebit')

const File = mongoose.model('File', { root: String, data: String })

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

async function main() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    var store = await createContract("Blockchain")
    var numtr = await createContract("NumTr", [store.options.address])
    var trsender = await createContract("TrSender", [store.options.address])
    var trreceiver = await createContract("TrReceiver", [store.options.address])
    var trdata = await createContract("TrData", [store.options.address])
    var getstorage = await createContract("GetStorage", [store.options.address])
    
    var obj = {
        store: store.options.address,
        numtr: numtr.options.address,
        trsender: trsender.options.address,
        trreceiver: trreceiver.options.address,
        trdata: trdata.options.address,
        getstorage: getstorage.options.address,
    }
    console.log(JSON.stringify(obj))
    process.exit(0)
}

main()

