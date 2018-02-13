
const Trie = require('merkle-patricia-tree')
const util = require('ethereumjs-util')
const levelup = require('levelup')
const leveldown = require('leveldown')
const RLP = require('rlp')

// 1) Create our store
var db = levelup(leveldown('./mydb'))
var trie = new Trie(db)

/*
for (var i = 0; i < 1000; i++) {
  console.log(RLP.encode(i).toString("hex"))
}
*/

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


