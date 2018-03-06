
const fs = require("fs")
const Web3 = require('web3')
var web3 = new Web3()
const RLP = require('rlp')
const util = require('ethereumjs-util')

var host = process.argv[2] || "programming-progress.com"

web3.setProvider(new web3.providers.WebsocketProvider('ws://' + host + ':8546'))

var dir = "compiled/"

var send_opt

async function createContract(name, args) {
    var code = "0x" + fs.readFileSync(dir + name + ".bin")
    var abi = JSON.parse(fs.readFileSync(dir + name + ".abi"))
    return new web3.eth.Contract(abi).deploy({data: code, arguments:args}).send(send_opt)
}

function toBytes2(str) {
    var buf = Buffer.from(str)
    var res = []
    for (var i = 0; i < buf.length; i++) res.push(buf[i])
    return JSON.stringify(res)
}

function toBytes(str) {
    return "0x" + Buffer.from(str).toString("hex")
}

async function doDeploy() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    var c = await createContract("Patricia")
    c.setProvider(web3.currentProvider)
    console.log("contract address", c.options.address)
    var tx = await c.methods.init(toBytes("test"), "0x1fef2cfba356215b30b6a0dd5b9dc6de5b61e7063d6eef179879d3061ba206c4").send(send_opt)
    console.log("init", tx)
    var tx = await c.methods.stepProof("0xe217a08661b431c3b0f714f67eddcd848f3f8e836b06d480c69d6672bfd817aa11b988").send(send_opt)
    console.log("step 1", tx)
    var debug = await c.methods.debug().call(send_opt)
    console.log("debug 1", debug)
    console.log("find idx 0", await c.methods.rlpFindBytes("0xe217a08661b431c3b0f714f67eddcd848f3f8e836b06d480c69d6672bfd817aa11b988", 0).call(send_opt))
    console.log("find idx 1", await c.methods.rlpFindBytes("0xe217a08661b431c3b0f714f67eddcd848f3f8e836b06d480c69d6672bfd817aa11b988", 1).call(send_opt))
    var len = await c.methods.rlpByteLength("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 0).call(send_opt)
    console.log("byte len", len)
    console.log("read size", await c.methods.readSize("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 1, 1).call(send_opt))
    var arr_len = await c.methods.rlpArrayLength("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 0).call(send_opt)
    console.log("find idx 0", await c.methods.rlpFindBytes("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 0).call(send_opt))
    console.log("find idx 1", await c.methods.rlpFindBytes("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 1).call(send_opt))
    console.log("find idx 2", await c.methods.rlpFindBytes("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 2).call(send_opt))
    console.log("find idx 3", await c.methods.rlpFindBytes("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 3).call(send_opt))
    console.log("find idx 4", await c.methods.rlpFindBytes("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080", 4).call(send_opt))
    console.log("arr len", arr_len)
    var tx = await c.methods.stepProof("0xf83a80808080c98420657374836f6e65808080808080a0d7f177d80fc4faa680eaa4f93d0934033222e66c04da89fb90be07c2e0f56ebe8080808080").send(send_opt)
    console.log("step 2", tx)
    var debug = await c.methods.debug().call(send_opt)
    console.log("debug 2", debug)
    process.exit(0)
}

function hash(dta) {
    return util.sha3(Buffer.from(dta,"hex"))
}

async function doDeployTx() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    var c = await createContract("Transaction")
    c.setProvider(web3.currentProvider)
    console.log("contract address", c.options.address)
    var res = await c.methods.check("0xf8648064830186a09401020304050607080910111213141516171819208084122334451ba021b407453d4daab0aa3de845d6dfd81ee7f75fe0e88e84a5b0743f742f1853f0a02fc5c0e2cbe3fa77252b3d5b13279aeb95ab12042351fbb0f744f78d2f588968").call(send_opt)
    console.log(res)
    var res = await c.methods.check("0xf8648064830186a09401020304050607080910111213141516171819208084122334451ca0985490fb6390efb7d88b609a371e2d623300ca8debd6db4946fa8ee206a27e8aa03979870657e436f7400120120c977488da5a9b5c9dde684c6bde5b0b54aac331").call(send_opt)
    console.log(res)
    
    var x = RLP.decode("0xf888820410018347b7609455dacfa8f7ce50fba76ef7b6b26ed1de78ee8a4680a47cec4fe20000000000000000000000000000000000000000000000000000000000000014820a95a03d7baa2cb542de65f4c355049e533def86c2ecbabc92fbcddc3abef74eb9c50fa05f633c31bbabf77220750926e0b055f8709f6d6b4d3293145d63dceadb174084")
    console.log(x.slice(0,6), RLP.encode(1337))
    
    console.log(hash(RLP.encode(x.slice(0,6).concat([1337, "", ""])).toString("hex")))
    console.log(hash(RLP.encode(x.slice(0,6)).toString("hex")))
    console.log(RLP.encode(x.slice(0,6)).toString("hex"))

    var res = await c.methods.check("0xf888820410018347b7609455dacfa8f7ce50fba76ef7b6b26ed1de78ee8a4680a47cec4fe20000000000000000000000000000000000000000000000000000000000000014820a95a03d7baa2cb542de65f4c355049e533def86c2ecbabc92fbcddc3abef74eb9c50fa05f633c31bbabf77220750926e0b055f8709f6d6b4d3293145d63dceadb174084").call(send_opt)
    console.log(res)
    process.exit(0)
}

// doDeploy()
doDeployTx()

