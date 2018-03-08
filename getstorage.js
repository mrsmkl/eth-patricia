#!/usr/bin/node

const fs = require("fs")
const Web3 = require("../web3.js/packages/web3")
const web3 = new Web3()
const RLP = require('rlp')
const util = require('ethereumjs-util')

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
    console.error(res)
    return res
}

function hash(dta) {
    return util.sha3(Buffer.from(dta.substr(2),"hex"))
}

function make32(str) {
    while (str.length < 64) str = "0"+str;
    return "0x"+str
}

async function main() {
    var lst = getList()
    console.error(lst)
    var blk = await web3.eth.getBlock(getInteger(lst[0]))
    console.error("Account", "0x"+lst[1].substr(24), blk.hash)
    var cell = await web3.eth.getStorageCell(blk.hash, "0x"+lst[1].substr(24), make32(lst[2]))
    cell = RLP.decode(cell).toString("hex")
    console.error(cell)
    fs.writeFileSync("custom.out", conv(cell), "hex")
}

main()


