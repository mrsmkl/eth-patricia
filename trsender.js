

const fs = require("fs")
const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()

// should read and write from custom.dta

var host = process.argv[2] || "localhost"

web3.setProvider(new web3.providers.HttpProvider('http://' + host + ':8545'))

function getList() {
    var str = fs.readFileSync("custom.in", "hex")
    var lst = []
    for (var i = 0; i < str.length; i += 64) lst.push(str.substr(i, 64))
    return lst
}

function conv(a) {
    while (a.length < 64) a = "0"+a
    return a
}

function getInteger(str) {
    var res = 0
    for (var i = 0; i < 64; i++) res = parseInt("0x"+str[i]) + res*16
    console.log(res)
    return res
}

async function main() {
    var lst = getList()
    var blk = await web3.eth.getBlock(getInteger(lst[0]))
    var tr_hash = blk.transactions[getInteger(lst[1])]
    var tr = await web3.eth.getTransaction(tr_hash)
    console.log(tr.from)
    fs.writeFileSync("custom.out", conv(tr.from.substr(2)), "hex")
}

main()


