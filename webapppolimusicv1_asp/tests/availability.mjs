// Regression check for intermittent ASP failures across fresh concurrent sessions.
import assert from 'node:assert/strict';
const base=process.env.POLIMUSIC_URL||'http://localhost/PoliMusic/';
for(let wave=0;wave<5;wave++){
    const results=await Promise.all(Array.from({length:12},async(_,index)=>{
        const path=index%2?'login.asp':'api.asp?action=session';
        const response=await fetch(new URL(path,base),{cache:'no-store'});
        const body=await response.text();
        assert.equal(response.status,200,`${path}: HTTP ${response.status}: ${body.slice(0,300)}`);
        if(index%2)assert.match(body,/id="auth-form"/);
        else assert.match(JSON.parse(body).csrf,/^[A-F0-9]{64}$/);
        return response.status;
    }));
    console.log(`PASS availability wave ${wave+1}: ${results.length} concurrent requests`);
}
