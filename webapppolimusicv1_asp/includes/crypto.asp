<%
// ES3-compatible SHA-256 / HMAC / PBKDF2 for the Classic ASP JScript engine.
// No passwords or password derivations are sent to the browser.
var Crypto = (function () {
    var K = [1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298];
    var initial = [1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225];
    function block(h,w) {
        var a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],n=h[7],i,x,y,t1,t2;
        for(i=16;i<64;i++){x=w[i-15];y=w[i-2];w[i]=(((x>>>7|x<<25)^(x>>>18|x<<14)^(x>>>3))+w[i-16]+((y>>>17|y<<15)^(y>>>19|y<<13)^(y>>>10))+w[i-7])|0;}
        for(i=0;i<64;i++){t1=(n+((e>>>6|e<<26)^(e>>>11|e<<21)^(e>>>25|e<<7))+((e&f)^(~e&g))+K[i]+w[i])|0;t2=(((a>>>2|a<<30)^(a>>>13|a<<19)^(a>>>22|a<<10))+((a&b)^(a&c)^(b&c)))|0;n=g;g=f;f=e;e=(d+t1)|0;d=c;c=b;b=a;a=(t1+t2)|0;}
        h[0]=(h[0]+a)|0;h[1]=(h[1]+b)|0;h[2]=(h[2]+c)|0;h[3]=(h[3]+d)|0;h[4]=(h[4]+e)|0;h[5]=(h[5]+f)|0;h[6]=(h[6]+g)|0;h[7]=(h[7]+n)|0;
        return h;
    }
    function hash(bytes) {
        var h=initial.slice(0),data=bytes.slice(0),bits=data.length*8,i,j,w=[];
        data.push(128);while(data.length%64!==56)data.push(0);
        for(i=7;i>=0;i--)data.push(i>=4?0:(bits>>>i*8)&255);
        for(i=0;i<data.length;i+=64){for(j=0;j<16;j++)w[j]=(data[i+j*4]<<24)|(data[i+j*4+1]<<16)|(data[i+j*4+2]<<8)|data[i+j*4+3];block(h,w);}
        return h;
    }
    function bytes(words){var out=[],i;for(i=0;i<words.length*4;i++)out.push((words[i>>>2]>>>(24-(i%4)*8))&255);return out;}
    function utf8(s){var raw=unescape(encodeURIComponent(s)),out=[],i;for(i=0;i<raw.length;i++)out.push(raw.charCodeAt(i));return out;}
    function hex(words){var b=bytes(words),s='',i;for(i=0;i<b.length;i++)s+=('0'+b[i].toString(16)).slice(-2);return s;}
    function pbkdf2(password,saltHex,iterations) {
        var key=utf8(password),pad=[],opad=[],i,j,salt=[],w=[],inner,outer,u,result;
        if(key.length>64)key=bytes(hash(key));
        for(i=0;i<64;i++){pad[i]=(key[i]||0)^54;opad[i]=(key[i]||0)^92;}
        for(i=0;i<16;i++)w[i]=(pad[i*4]<<24)|(pad[i*4+1]<<16)|(pad[i*4+2]<<8)|pad[i*4+3];
        inner=block(initial.slice(0),w);
        for(i=0;i<16;i++)w[i]=(opad[i*4]<<24)|(opad[i*4+1]<<16)|(opad[i*4+2]<<8)|opad[i*4+3];
        outer=block(initial.slice(0),w);
        function finish(state,input,length){var a=input.slice(0);a.push(128);while(a.length%64!==56)a.push(0);for(var k=7;k>=0;k--)a.push(k>=4?0:((length*8)>>>k*8)&255);var h=state.slice(0);for(var p=0;p<a.length;p+=64){for(var z=0;z<16;z++)w[z]=(a[p+z*4]<<24)|(a[p+z*4+1]<<16)|(a[p+z*4+2]<<8)|a[p+z*4+3];block(h,w);}return h;}
        for(i=0;i<saltHex.length;i+=2)salt.push(parseInt(saltHex.substr(i,2),16));salt.push(0,0,0,1);
        u=finish(outer,bytes(finish(inner,salt,64+salt.length)),96);result=u.slice(0);
        // Each following HMAC processes exactly one 32-byte block per precomputed state.
        for(i=1;i<iterations;i++){
            for(j=0;j<8;j++)w[j]=u[j];w[8]=0x80000000;for(j=9;j<15;j++)w[j]=0;w[15]=768;
            u=block(inner.slice(0),w);
            for(j=0;j<8;j++)w[j]=u[j];w[8]=0x80000000;for(j=9;j<15;j++)w[j]=0;w[15]=768;
            u=block(outer.slice(0),w);for(j=0;j<8;j++)result[j]^=u[j];
        }
        return hex(result);
    }
    function equal(a,b){a=String(a);b=String(b);var difference=a.length^b.length;for(var i=0;i<a.length;i++)difference|=a.charCodeAt(i)^b.charCodeAt(i%b.length);return difference===0;}
    return { pbkdf2:pbkdf2, sha256:function(s){return hex(hash(utf8(s)));}, equal:equal };
})();
if(typeof module!=='undefined')module.exports=Crypto;
%>
