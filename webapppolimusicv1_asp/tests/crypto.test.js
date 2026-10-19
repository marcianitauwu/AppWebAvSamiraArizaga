'use strict';
const assert=require('node:assert/strict');
const native=require('node:crypto');
const fs=require('node:fs');
const vm=require('node:vm');
const source=fs.readFileSync(require('node:path').join(__dirname,'../includes/crypto.asp'),'utf8').replace(/^<%/,'').replace(/%>\s*$/,'');
const context={module:{exports:{}}};vm.runInNewContext(source,context);const crypto=context.module.exports;
for(const message of ['','abc','PoliMusic á ñ 🎵','a'.repeat(1000)]){
    assert.equal(crypto.sha256(message),native.createHash('sha256').update(message).digest('hex'));
}
for(const[password,salt,iterations]of[
    ['password','73616c74',1],['password','73616c74',2],
    ['Contraseña🎵123','aabbccddeeff00112233445566778899',4096],
    ['x'.repeat(128),'0123456789abcdef',1000],
    ['PasswordVector_600k!','00112233445566778899aabbccddeeff',600000]
]){
    assert.equal(crypto.pbkdf2(password,salt,iterations),native.pbkdf2Sync(password,Buffer.from(salt,'hex'),iterations,32,'sha256').toString('hex'));
}
assert.equal(crypto.equal('abc','abc'),true);
assert.equal(crypto.equal('abc','abd'),false);
assert.equal(crypto.equal('abc',''),false);
assert.equal(crypto.equal('abc','abcx'),false);
console.log('PASS: SHA-256, PBKDF2-SHA256 and constant-work comparison match native cryptography.');
