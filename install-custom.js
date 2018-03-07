
const fs = require("fs")

var config = JSON.parse(fs.readFileSync("config.json"))

config.interpreter_args = config.interpreter_args.concat([
    "-custom", "200,_readBlockTransactions,/home/sami/patricia/numtr.js",
    "-custom", "201,_readTransactionReceiver,/home/sami/patricia/trreceiver.js",
    "-custom", "202,_readTransactionSender,/home/sami/patricia/trsender.js",
    "-custom", "203,_readTransactionData,/home/sami/patricia/trdata.js",
    "-custom", "204,_readAccountStorage,/home/sami/patricia/getstorage.js"
])

fs.writeFileSync("config.json", JSON.stringify(config))
