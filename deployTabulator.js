
const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()
const fs = require("fs")

var host = process.argv[2] || "localhost"

web3.setProvider(new web3.providers.WebsocketProvider('ws://' + host + ':8546'))
// web3.setProvider(new web3.providers.HttpProvider('http://' + host + ':8545'))

var config = JSON.parse(fs.readFileSync("/home/sami/webasm-solidity/node/config.json"))

const dir = "./compiled/"

var send_opt

var filesystem = new web3.eth.Contract(JSON.parse(fs.readFileSync("/home/sami/webasm-solidity/contracts/compiled/Filesystem.abi")), config.fs)

async function createContract(name, args) {
    var code = "0x" + fs.readFileSync(dir + name + ".bin")
    var abi = JSON.parse(fs.readFileSync(dir + name + ".abi"))
    return new web3.eth.Contract(abi).deploy({data: code, arguments:args}).send(send_opt)
}

var config = JSON.parse(fs.readFileSync("../webasm-solidity/node/config.json"))

async function outputFile(id) {
    var lst = await filesystem.methods.getData(id).call(send_opt)
    console.log("File data for", id, "is", lst)
}

async function main() {
    var accts = await web3.eth.getAccounts()
    send_opt = {gas:4700000, from:accts[0]}
    var code_address = "QmXK6KErDRMLDXa5kJ8pqafHLPT18aD8U7XdybWXfToWTh"
    var init_hash = "0x5df7bb33c60adef9bd1b3442db01300ddeda104dfd159a5f25b7e0a413ddfe5e"
    var tab = await createContract("Tabulate", [config.tasks, config.fs, code_address, init_hash])
    
    console.log(tab.options.address)
    
    tab.methods.tabulateElection("0x5e4E5592c9e0110959135FCB69DdAe86F5A8DC1d", "0x5e4E5592c9e0110959135FCB69DdAe86F5A8DC1d", 0x268, 0x26c).send(send_opt)
    
    tab.events.GotFiles(function (err,ev) {
        if (err) return console.log(err)
        console.log("Files", ev.returnValues)
        var files = ev.returnValues.files
    
        files.forEach(outputFile)
    })
}

main()

