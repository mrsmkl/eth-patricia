
const fs = require("fs")

const lst = JSON.parse(process.argv[2])
const fname = process.argv[3] || "custom.in"

function conv(a) {
    a = a.toLowerCase()
    while (a.length < 64) a = "0"+a
    console.log(a)
    console.log(Buffer.from(a, "hex"))
    return a
}

function main() {
    var res = Buffer.alloc(10000)
    var len = 0
    lst.forEach(a => {
        len += res.write(conv(a), len, "hex")
        console.log(len)
    })
    console.log(res)
    fs.writeFileSync(fname, Buffer.from(res.toString("hex", 0, len), "hex"))
}

main()
