import assert from 'node:assert/strict';

const base=process.env.POLIMUSIC_URL||'http://localhost:8091/';
const password=process.env.POLIMUSIC_TEST_PASSWORD;
if(!password)throw new Error('Set POLIMUSIC_TEST_PASSWORD to the demo account password.');
class Client{
    cookies=new Map();csrf='';
    async request(path,body,headers={}){
        const options={redirect:'manual',headers:{...headers,Cookie:[...this.cookies].map(([k,v])=>`${k}=${v}`).join('; ')}};
        if(body){options.method='POST';options.body=new URLSearchParams(body);}
        const response=await fetch(new URL(path,base),options);
        for(const cookie of response.headers.getSetCookie()){const[name,...value]=cookie.split(';')[0].split('=');this.cookies.set(name,value.join('='));}
        const buffer=Buffer.from(await response.arrayBuffer()),text=buffer.toString();let data;try{data=JSON.parse(text);}catch{}
        return {status:response.status,data,text,buffer,headers:response.headers};
    }
    async api(action,body,expected=200,extra=''){
        const response=await this.request(`api.asp?action=${action}${extra}`,body?{...body,csrf:this.csrf}:undefined);
        assert.equal(response.status,expected,`${action}: ${response.text.slice(0,1000)}`);return response.data;
    }
    async session(){const session=await this.api('session');this.csrf=session.csrf;return session;}
    async login(username){await this.session();const started=Date.now();const result=await this.api('login',{username,password});assert.equal(result.redirect,'welcome.asp');const welcome=await this.request('welcome.asp');assert.equal(welcome.status,302);const session=await this.session();assert.equal(session.user.username,username);console.log(`PASS login ${username} (${((Date.now()-started)/1000).toFixed(1)}s)`);return session.user;}
}
const anon=new Client();
await anon.session();await anon.api('catalog',null,401);await anon.api('admin-list',null,401,'&entity=users');
for(const path of ['App_Data/connection.txt','includes/crypto.asp','database/001-security.sql','SongFilesAndImages_resources/SongFiles/bensound-adventure.mp3']){
    const response=await anon.request(path);assert.equal(response.status,404,`Protected ${path}`);
}
console.log('PASS anonymous access and private files blocked');
const normal=new Client(),admin=new Client();
assert.equal(Number((await normal.login('Samira.Arizaga')).role),0);
const catalog=await normal.api('catalog');
const bindingCookie=normal.cookies.get('PM_AUTH');normal.cookies.delete('PM_AUTH');await normal.api('catalog',null,401);normal.cookies.set('PM_AUTH',bindingCookie);
assert.ok(catalog.songs.some(s=>s.available));assert.ok(!catalog.playlists.some(p=>Number(p.privacy)===1&&Number(p.ownerId)!==Number(catalog.user.id)));
for(const entity of ['users','songs','artists','albums','playlists']){
    await normal.api('admin-list',null,403,`&entity=${entity}`);
    await normal.api('admin-save',{entity,id:'0'},403);
    await normal.api('admin-delete',{entity,id:'1'},403);
}
const track=catalog.songs.find(s=>s.available);
const ranged=await normal.request(`stream.asp?id=${track.id}`,null,{Range:'bytes=0-1023'});
assert.equal(ranged.status,206);assert.equal(ranged.buffer.length,1024);assert.match(ranged.headers.get('content-type'),/^audio\//);
const invalidRange=await normal.request(`stream.asp?id=${track.id}`,null,{Range:'bytes=999999999-'});assert.equal(invalidRange.status,416);
await anon.request(`stream.asp?id=${track.id}`).then(r=>assert.equal(r.status,401));
const csrfTest=await normal.request('api.asp?action=play',{id:track.id,csrf:'invalid'});assert.equal(csrfTest.status,403);
const unavailable=catalog.songs.find(s=>!s.available);if(unavailable)await normal.request(`stream.asp?id=${unavailable.id}`).then(r=>assert.equal(r.status,404));
console.log('PASS normal RBAC, playlist privacy, audio ranges and CSRF');
const adminUser=await admin.login('userAdmin');assert.equal(Number(adminUser.role),1);
const created=[];const suffix=Date.now();
async function save(entity,body){return admin.api('admin-save',{entity,id:0,...body});}
async function remove(entity,id){await admin.api('admin-delete',{entity,id});}
try{
    const artist=await save('artists',{name:'QA '+suffix,lastname:'Prueba',image:''});created.push(['artists',artist.id]);
    const album=await save('albums',{title:'QA Álbum '+suffix,year:2026,image:'',songIds:''});created.push(['albums',album.id]);
    const song=await save('songs',{title:'QA Canción '+suffix,path:'SongFilesAndImages_resources/SongFiles/bensound-adventure.mp3',plays:0,artistIds:artist.id,albumIds:album.id});created.push(['songs',song.id]);
    const user=await save('users',{username:'qa.'+suffix,email:`qa.${suffix}@polimusic.local`,role:0,password,birthday:'2000-01-01',image:''});created.push(['users',user.id]);
    const playlist=await save('playlists',{title:'QA Playlist '+suffix,ownerId:user.id,privacy:1,image:'',songIds:song.id});created.push(['playlists',playlist.id]);
    let all=await admin.api('catalog');
    assert.deepEqual(all.songs.find(s=>Number(s.id)===song.id).artistIds,[artist.id]);
    assert.ok(all.albums.find(a=>Number(a.id)===album.id).songIds.includes(song.id));
    assert.ok(all.playlists.find(p=>Number(p.id)===playlist.id).songIds.includes(song.id));
    assert.ok(!(await normal.api('catalog')).playlists.some(p=>Number(p.id)===playlist.id));
    await admin.api('admin-save',{entity:'artists',id:artist.id,name:'QA Editado '+suffix,lastname:'Prueba',image:''});
    await admin.api('admin-save',{entity:'albums',id:album.id,title:'QA Editado '+suffix,year:2025,image:'',songIds:song.id});
    await admin.api('admin-save',{entity:'songs',id:song.id,title:'QA Editado '+suffix,path:'SongFilesAndImages_resources/SongFiles/bensound-adventure.mp3',plays:2,artistIds:artist.id,albumIds:album.id});
    await admin.api('admin-save',{entity:'users',id:user.id,username:'qa.'+suffix,email:`qa.${suffix}@polimusic.local`,role:0,password:'',birthday:'2000-02-02',image:''});
    await admin.api('admin-save',{entity:'playlists',id:playlist.id,title:'QA Editado '+suffix,ownerId:user.id,privacy:0,image:'',songIds:song.id});
    assert.ok((await normal.api('catalog')).playlists.some(p=>Number(p.id)===playlist.id));
    for(const[entity]of created){const result=await admin.api('admin-list',null,200,`&entity=${entity}`);assert.ok(result.items.length);}
    await admin.api('admin-delete',{entity:'users',id:adminUser.id},400);
    await admin.api('admin-save',{entity:'songs',id:song.id,title:'QA inválido',path:'../../App_Data/connection.txt',plays:0,artistIds:'',albumIds:''},400);
    const after=await admin.api('catalog');assert.equal(after.songs.find(s=>Number(s.id)===song.id).title,'QA Editado '+suffix);
    console.log('PASS admin CRUD for all five entities, relations, transactions and self-protection');
}finally{for(const[entity,id]of created.reverse()){await remove(entity,id);}}
// Registration ignores a forged administrator role.
const registered='qa.register.'+suffix;
await anon.api('register',{username:registered,email:`reg.${suffix}@polimusic.local`,password,confirm:password,role:1});
const registrationClient=new Client();const registeredUser=await registrationClient.login(registered);assert.equal(Number(registeredUser.role),0);
await registrationClient.api('admin-list',null,403,'&entity=users');
await registrationClient.api('logout',{});await registrationClient.api('catalog',null,401);
await remove('users',registeredUser.id);
await normal.api('logout',{});await normal.api('catalog',null,401);
await admin.api('logout',{});await admin.api('catalog',null,401);
console.log('PASS registration, forced normal role, logout and test data cleanup');
console.log('ALL INTEGRATION CHECKS PASSED');
