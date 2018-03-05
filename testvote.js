// populate the voting contract with transactions

const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()
const fs = require("fs")

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
    var vote = await createContract("Vote")
    console.log("Contract at", vote.options.address)
    var bnum1 = await web3.eth.getBlockNumber()
    await vote.methods.yes().send({gas:4700000, from:accts[0], gasPrice:1})
    console.log("Vote 1")
    await vote.methods.no().send({gas:4700000, from:accts[1], gasPrice:1})
    console.log("Vote 2")
    await vote.methods.yes().send({gas:4700000, from:accts[2], gasPrice:1})
    console.log("Vote 3")
    await vote.methods.yes().send({gas:4700000, from:accts[3], gasPrice:1})
    console.log("Vote 4")
    var bnum2 = await web3.eth.getBlockNumber()
    console.log("Start block", bnum1, "End block", bnum2)
}

main()

