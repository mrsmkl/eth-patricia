
const fs = require("fs")
const Web3 = require('web3')
var web3 = new Web3()

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

async function doDeployTx() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    var c = await createContract("Transaction")
    c.setProvider(web3.currentProvider)
    console.log("contract address", c.options.address)
    var res = await c.methods.check("0xf8648064830186a09401020304050607080910111213141516171819208084122334451ba0d02ed7f1d0868b5935e1e2e15e99a49a3a0e8b2f7a3c089cd34d8d978dfde1f7a0529cfe3fd05fbb32ebb4d415d35b5a9ae62c2381969d903c6d4f70fe66bd999a").call(send_opt)
    console.log(res)
    process.exit(0)
}

doDeploy()
// doDeployTx()

