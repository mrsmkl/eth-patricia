
const Trie = require('merkle-patricia-tree')
const util = require('ethereumjs-util')
const levelup = require('levelup')
const leveldown = require('leveldown')
const rocksdb = require('rocksdb')
const RLP = require('rlp')

// 1) Create our store
// var db = levelup(leveldown('./mydb'))
var db = levelup(rocksdb('./myrocks'))
var trie = new Trie(db)

// for (var i = 0; i < 1000; i++) console.log(RLP.encode(i).toString("hex"))

function arr(buf) {
    var res = []
    for (var i = 0; i < buf.length; i++) res.push(buf[i])
    return JSON.stringify(res)
}

var asd = Buffer.from("c98420657374836f6e65", "hex")
console.log("hash of c98420657374836f6e65", util.sha3(asd).toString("hex"))

function putKeys(trie, lst, cb) {
    var i = 0
    function handle() {
        i++;
        if (i == lst.length) cb()
    }
    lst.forEach(arr => console.log(Buffer.from(arr[0]).toString("hex"), Buffer.from(arr[1]).toString("hex")))
    lst.forEach(arr => trie.put(arr[0], arr[1], handle))
    if (lst.length == 0) cb()
}

function info(node) {
    return {
        hex: node.toString("hex"),
        length: node.length,
        hash: util.sha3(node).toString("hex"),
        arr_len: node[0]-192,
        rlp: RLP.decode(node),
        arr: arr(node),
    }
}

putKeys(trie, [[RLP.encode(123), util.sha3('one')], ["test", "one"]], function () {
  trie.get(RLP.encode(123), function (err, value) {
    if(value) console.log(value.toString("hex"))

    console.log(trie.root.toString("hex"))
    Trie.prove(trie, 'test', function (err, proof) {
        if (err) return console.log(err)
        console.log(proof.map(info))
        Trie.verifyProof(trie.root, 'test', proof, function (err, value) {
            if (err) return console.log(err)
            console.log(value.toString())
        })
    })
  })
})

var Transaction = require('ethereumjs-tx')

// create a blank transaction
var tx = new Transaction(null, 1) // mainnet Tx EIP155

// So now we have created a blank transaction but Its not quiet valid yet. We
// need to add some things to it. Lets start:
// notice we don't set the `to` field because we are creating a new contract.
tx.nonce = 0
tx.gasPrice = 100
tx.gasLimit = 1000
tx.value = 0
tx.data = '0x12233445'
tx.to = '0x0102030405060708091011121314151617181920'

var privateKey = new Buffer('e331b6d69882b4cb4ea581d88e0b604039a3de5967688d3dcffdd2270c0fd109', 'hex')
// We have a signed transaction, Now for it to be fully fundable the account that we signed
// it with needs to have a certain amount of wei in to. To see how much this
// account needs we can use the getUpfrontCost() method.
var feeCost = tx.getUpfrontCost()
tx.gas = feeCost
console.log('Total Amount of wei needed:' + feeCost.toString())

// if your wondering how that is caculated it is
// bytes(data length) * 5
// + 500 Default transaction fee
// + gasAmount * gasPrice

// lets serialize the transaction

console.log('---Serialized TX----')
console.log(tx.serialize().toString('hex'))
console.log(info(tx.serialize()))
tx.sign(privateKey)
console.log(info(tx.serialize()))
console.log(info(RLP.encode(tx.to)))
console.log('--------------------')


