'use strict';
const $ = (s,root=document)=>root.querySelector(s);
const $$ = (s,root=document)=>[...root.querySelectorAll(s)];
const escapeHTML = value => String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const icon = name => `<svg class="icon" aria-hidden="true"><use href="assets/icons.svg#${name}"/></svg>`;
const content=$('#content'),audio=$('#audio');
let catalog,csrf,queue=[],current=null,shuffle=false,repeat=false,adminEntity='users',adminItems=[],adminRelations={},resources=[],users=[],editorId=0,deleteId=0,routeVersion=0;
let toastTimer,searchTimer,playGeneration=0;
const entityLabels={users:'Usuarios',songs:'Canciones',artists:'Artistas',albums:'Álbumes',playlists:'Playlists'};
const singular={users:'usuario',songs:'canción',artists:'artista',albums:'álbum',playlists:'playlist'};
const matches=(value,term)=>String(value??'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().includes(term.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase());
const artistName=artist=>`${artist.name} ${artist.lastname||''}`.trim();
const songArtists=song=>(song.artistIds||[]).map(id=>catalog.artists.find(a=>Number(a.id)===id)).filter(Boolean);
const songArtistText=song=>songArtists(song).map(artistName).join(', ')||'Artista sin asignar';
const songById=id=>catalog.songs.find(song=>Number(song.id)===Number(id));
const songsOf=ids=>(ids||[]).map(songById).filter(Boolean);
function toast(message){const el=$('#toast');el.textContent=message;el.hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.hidden=true,4500);}
async function api(action,body,extra=''){
    const options={cache:'no-store'};
    if(body){options.method='POST';options.body=new URLSearchParams({...body,csrf});}
    const response=await fetch(`api.asp?action=${action}${extra}`,options);
    let data;try{data=await response.json();}catch{throw new Error('El servidor no pudo responder. Comprueba la configuración de IIS.');}
    if(response.status===401){audio.pause();location.assign('login.asp');throw new Error('Tu sesión ha expirado.');}
    if(!response.ok)throw new Error(data.error||'No se pudo completar la operación.');
    return data;
}
function intro(title,description,eyebrow='TU UNIVERSO MUSICAL'){
    return `<div class="page-intro"><div><div class="eyebrow">${escapeHTML(eyebrow)}</div><h1>${escapeHTML(title)}</h1><p>${escapeHTML(description)}</p></div><span class="date-label">${escapeHTML(new Intl.DateTimeFormat('es-EC',{day:'numeric',month:'long',year:'numeric'}).format(new Date()))}</span></div>`;
}
function section(title,link,label='Ver todo'){return `<div class="section-heading"><h2>${escapeHTML(title)}</h2>${link?`<a href="${link}">${escapeHTML(label)} ${icon('chevron-right')}</a>`:''}</div>`;}
function empty(title,message){return `<div class="empty-state">${icon('music')}<h2>${escapeHTML(title)}</h2><p>${escapeHTML(message)}</p></div>`;}
function collectionCard(item,type){
    const artists=type==='artists',title=artists?artistName(item):item.title;
    const description=artists?'Artista':type==='albums'?`${item.year||'Sin año'} · Álbum`:`${item.songIds.length} canciones${Number(item.privacy)===1?' · Privada':''}`;
    const playable=songsOf(item.songIds).some(song=>song.available);
    return `<article class="music-card ${artists?'artist-card':''}"><div class="cover-wrap"><a href="#${type}/${item.id}" tabindex="-1" aria-hidden="true"><img src="${escapeHTML(item.image)}" alt="" loading="lazy"></a>${playable?`<button class="card-play" data-play-collection="${type}/${item.id}" aria-label="Reproducir ${escapeHTML(title)}">${icon('play')}</button>`:''}</div><a href="#${type}/${item.id}"><h3>${escapeHTML(title)}</h3></a><p>${escapeHTML(description)}</p></article>`;
}
function cards(items,type,home=false){return items.length?`<div class="cards ${home?'home-cards':''}">${items.map(item=>collectionCard(item,type)).join('')}</div>`:empty('Aún no hay contenido','El administrador puede agregar contenido desde su panel.');}
function songTable(songs,context='songs'){
    if(!songs.length)return empty('Todavía no hay canciones','Prueba con otra búsqueda o explora el catálogo.');
    return `<div class="table-wrap"><table class="song-table"><thead><tr><th aria-label="Número">#</th><th>Título</th><th class="album-column">Álbum</th><th class="plays-column">Reproducciones</th><th>Escuchar</th></tr></thead><tbody>${songs.map((song,i)=>{
        const album=catalog.albums.find(a=>song.albumIds.includes(Number(a.id)));
        return `<tr data-song-row="${song.id}" class="${current&&Number(current.id)===Number(song.id)?'is-current':''}"><td>${String(i+1).padStart(2,'0')}</td><td><div class="song-info"><img src="${escapeHTML(song.image)}" alt="" loading="lazy"><div><strong>${escapeHTML(song.title)}</strong><small>${songArtists(song).map(artist=>`<a href="#artists/${artist.id}">${escapeHTML(artistName(artist))}</a>`).join(', ')||'Artista sin asignar'}</small></div></div></td><td class="album-column">${album?`<a href="#albums/${album.id}">${escapeHTML(album.title)}</a>`:'—'}</td><td class="plays-column">${Number(song.plays).toLocaleString('es-EC')}</td><td>${song.available?`<button class="row-play" data-play="${song.id}" data-context="${escapeHTML(context)}" aria-label="Reproducir ${escapeHTML(song.title)}">${icon(current&&Number(current.id)===Number(song.id)&&!audio.paused?'pause':'play')}</button>`:'<span class="availability" title="Agrega el archivo de audio desde Administración">No disponible</span>'}</td></tr>`;
    }).join('')}</tbody></table></div>`;
}
function renderHome(){
    const hour=new Date().getHours(),greeting=hour<12?'Buenos días':hour<19?'Buenas tardes':'Buenas noches';
    const first=catalog.songs.find(song=>song.available),quick=catalog.albums.slice(0,3);
    content.innerHTML=intro(`${greeting}, ${catalog.user.username.split('.')[0]}.`,'Un nuevo momento para encontrar tu ritmo.','BIENVENIDO A POLIMUSIC')+
    `<nav class="filter-pills" aria-label="Explorar contenido"><a class="active" href="#home">Para ti</a><a href="#songs">Música</a><a href="#albums">Álbumes</a><a href="#artists">Artistas</a></nav>
    <section class="hero"><div class="hero-copy"><div class="eyebrow">DESCUBRE · ESCUCHA · CONECTA</div><h2>Tu próxima canción<br>favorita está aquí.</h2><p>Desconecta del ruido. Conecta con la música.<br>Haz de este momento tu mejor playlist.</p><button class="button" ${first?`data-play="${first.id}"`:'data-explore="songs"'}>${icon('play')} ${first?'Empieza a escuchar':'Explorar canciones'}</button></div><div class="hero-vinyl" aria-hidden="true"><div class="vinyl-label"><strong>poli.</strong><small>GOOD MUSIC. GOOD MOOD.</small></div></div><span class="hero-tag">${icon('headphones')} EL SONIDO DE TU MOMENTO</span></section>
    ${quick.length?`<div class="quick-grid">${quick.map(album=>`<a class="quick-card" href="#albums/${album.id}"><img src="${escapeHTML(album.image)}" alt=""><strong>${escapeHTML(album.title)}</strong>${icon('chevron-right')}</a>`).join('')}</div>`:''}
    ${section('Hechos para tu momento','#albums')}${cards(catalog.albums,'albums',true)}
    ${section('Dale play a algo bueno','#songs')}${songTable([...catalog.songs].sort((a,b)=>b.plays-a.plays).slice(0,5),'popular')}
    ${section('Voces que conectan','#artists')}${cards(catalog.artists,'artists',true)}
    <div class="editorial-note">${icon('headphones')}<p><strong>La música es mejor cuando es tuya.</strong><br>Explora los álbumes y encuentra ese sonido que quieres volver a escuchar.</p></div>`;
}
function renderCollection(type,id){
    const item=catalog[type].find(item=>Number(item.id)===Number(id));
    if(!item){content.innerHTML=empty('No encontramos esta colección','Puede que se haya eliminado o que no tengas acceso.');return;}
    const title=type==='artists'?artistName(item):item.title,songs=songsOf(item.songIds),available=songs.some(song=>song.available);
    content.innerHTML=`<section class="collection-hero ${type==='artists'?'artist':''}"><img src="${escapeHTML(item.image)}" alt="${escapeHTML(title)}"><div><div class="eyebrow">${type==='artists'?'ARTISTA':type==='albums'?'ÁLBUM':Number(item.privacy)===1?'PLAYLIST PRIVADA':'PLAYLIST PÚBLICA'}</div><h1>${escapeHTML(title)}</h1><p>PoliMusic ${item.year?'· '+escapeHTML(item.year):''} · ${songs.length} canciones · ${songs.filter(s=>s.available).length} disponibles</p></div></section><div class="collection-actions">${available?`<button class="button primary" data-play-collection="${type}/${item.id}">${icon('play')}Reproducir</button>`:''}<span class="count-label">${songs.length?'Tu próxima favorita puede estar aquí.':'Esta colección aún no tiene canciones.'}</span></div>${songTable(songs,type+'/'+id)}`;
}
function renderSearch(){
    const term=$('#global-search').value.trim();
    content.innerHTML=intro(term?`Resultados para “${term}”`:'Encuentra tu próximo sonido.','Busca canciones, artistas, álbumes y playlists.','EXPLORAR');
    if(!term){content.innerHTML+=section('Explora los álbumes')+cards(catalog.albums,'albums');return;}
    const songs=catalog.songs.filter(s=>matches(s.title,term)||matches(songArtistText(s),term));
    const albums=catalog.albums.filter(a=>matches(a.title,term));
    const artists=catalog.artists.filter(a=>matches(artistName(a),term));
    const playlists=catalog.playlists.filter(p=>matches(p.title,term));
    if(!songs.length&&!albums.length&&!artists.length&&!playlists.length){content.innerHTML+=empty('No encontramos coincidencias','Prueba otro nombre de canción, artista o álbum.');return;}
    if(songs.length)content.innerHTML+=section('Canciones')+songTable(songs,'search');
    if(artists.length)content.innerHTML+=section('Artistas')+cards(artists,'artists');
    if(albums.length)content.innerHTML+=section('Álbumes')+cards(albums,'albums');
    if(playlists.length)content.innerHTML+=section('Playlists')+cards(playlists,'playlists');
}
function renderQueue(){
    $('#queue-list').innerHTML=queue.length?queue.map((song,i)=>`<div class="queue-item"><div><strong>${escapeHTML(song.title)}${current&&song.id===current.id?' · Ahora':''}</strong><span>${escapeHTML(songArtistText(song))}</span></div><button class="row-play" data-queue-index="${i}" aria-label="Reproducir ${escapeHTML(song.title)}">${icon('play')}</button></div>`).join(''):'<p class="muted">Reproduce una canción para empezar.</p>';
}
function syncPlayUI(){
    const playing=!audio.paused&&!!current;
    $('#toggle-play').innerHTML=icon(playing?'pause':'play');$('#toggle-play').setAttribute('aria-label',playing?'Pausar':'Reproducir');
    $$('[data-song-row]').forEach(row=>{const isCurrent=current&&Number(row.dataset.songRow)===Number(current.id);row.classList.toggle('is-current',!!isCurrent);const button=$('[data-play]',row);if(button)button.innerHTML=icon(isCurrent&&playing?'pause':'play');});
}
async function playSong(song,newQueue,force=false){
    if(!song?.available){toast('El archivo de audio de esta canción no está disponible.');return;}
    if(newQueue)queue=newQueue.filter(s=>s.available);
    if(current&&Number(current.id)===Number(song.id)&&audio.src&&!force){if(audio.paused)try{await audio.play();}catch{toast('No se pudo reproducir el audio.');}else audio.pause();return;}
    const generation=++playGeneration;current=song;
    if(!queue.some(s=>s.id===song.id))queue=[song];
    $('#now-title').textContent=song.title;$('#now-artist').textContent=songArtistText(song);$('#now-cover').src=song.image;
    audio.src=`stream.asp?id=${song.id}`;$('#seek').value=0;$('#seek').disabled=true;renderQueue();syncPlayUI();
    try{await audio.play();if(generation===playGeneration){await api('play',{id:song.id});song.plays++;}}
    catch(error){if(generation===playGeneration&&error.name!=='AbortError')toast(error.message||'No se pudo reproducir el archivo.');}
}
function nextSong(previous=false){
    if(!queue.length){const available=catalog.songs.filter(s=>s.available);if(available.length)playSong(available[0],available);return;}
    if(previous&&audio.currentTime>3){audio.currentTime=0;return;}
    let index=queue.findIndex(s=>current&&s.id===current.id);
    if(shuffle&&queue.length>1){let next;do{next=Math.floor(Math.random()*queue.length);}while(next===index);index=next;}
    else index=(index+(previous?-1:1)+queue.length)%queue.length;
    playSong(queue[index],null,true);
}
function queueForContext(context){
    if(context==='popular')return [...catalog.songs].sort((a,b)=>b.plays-a.plays);
    if(context==='search'){const term=$('#global-search').value.trim();return catalog.songs.filter(s=>matches(s.title,term)||matches(songArtistText(s),term));}
    if(context?.includes('/')){const[type,id]=context.split('/');return songsOf(catalog[type]?.find(i=>Number(i.id)===Number(id))?.songIds);}
    return catalog.songs;
}
function playCollection(path){const[type,id]=path.split('/'),item=catalog[type]?.find(i=>Number(i.id)===Number(id)),songs=songsOf(item?.songIds).filter(s=>s.available);if(!songs.length)toast('Esta colección aún no tiene archivos de audio disponibles.');else playSong(songs[0],songs,true);}
function seconds(value){if(!Number.isFinite(value))return '0:00';return `${Math.floor(value/60)}:${String(Math.floor(value%60)).padStart(2,'0')}`;}
function updateTimeline(){const duration=audio.duration;$('#elapsed').textContent=seconds(audio.currentTime);$('#duration').textContent=seconds(duration);$('#seek').disabled=!Number.isFinite(duration)||duration<=0;$('#seek').value=duration?Math.round(audio.currentTime/duration*1000):0;}
audio.volume=.75;
audio.addEventListener('timeupdate',updateTimeline);audio.addEventListener('loadedmetadata',updateTimeline);
audio.addEventListener('play',syncPlayUI);audio.addEventListener('pause',syncPlayUI);
audio.addEventListener('error',()=>{toast('No se pudo cargar el audio. Verifica su archivo o vuelve a iniciar sesión.');syncPlayUI();});
audio.addEventListener('ended',()=>{if(repeat){audio.currentTime=0;audio.play().catch(()=>{});}else if(queue.length>1)nextSong();else syncPlayUI();});
$('#toggle-play').addEventListener('click',()=>{if(!catalog)return;if(current){if(audio.paused)audio.play().catch(()=>toast('No se pudo reproducir el audio.'));else audio.pause();}else nextSong();});
$('#next').addEventListener('click',()=>catalog&&nextSong());$('#previous').addEventListener('click',()=>catalog&&nextSong(true));
$('#shuffle').addEventListener('click',event=>{shuffle=!shuffle;event.currentTarget.setAttribute('aria-pressed',String(shuffle));event.currentTarget.setAttribute('aria-label',shuffle?'Desactivar reproducción aleatoria':'Activar reproducción aleatoria');toast(shuffle?'Reproducción aleatoria activada':'Reproducción aleatoria desactivada');});
$('#repeat').addEventListener('click',event=>{repeat=!repeat;event.currentTarget.setAttribute('aria-pressed',String(repeat));toast(repeat?'Repetición de canción activada':'Repetición desactivada');});
$('#seek').addEventListener('input',event=>{if(Number.isFinite(audio.duration))audio.currentTime=Number(event.target.value)/1000*audio.duration;});
function syncVolume(){const muted=audio.muted||audio.volume===0;$('#mute').innerHTML=icon(muted?'muted':'volume');$('#mute').setAttribute('aria-label',muted?'Activar sonido':'Silenciar');}
$('#volume').addEventListener('input',event=>{audio.volume=Number(event.target.value)/100;audio.muted=false;syncVolume();});
$('#mute').addEventListener('click',()=>{audio.muted=!audio.muted;syncVolume();});
function closeQueue(){$('#queue-panel').hidden=true;$('#queue-toggle').setAttribute('aria-expanded','false');}
$('#queue-toggle').addEventListener('click',()=>{const panel=$('#queue-panel');panel.hidden=!panel.hidden;$('#queue-toggle').setAttribute('aria-expanded',String(!panel.hidden));if(catalog)renderQueue();});
$('#queue-close').addEventListener('click',closeQueue);
$('#menu-toggle').addEventListener('click',event=>{const open=$('#sidebar').classList.toggle('is-open');event.currentTarget.setAttribute('aria-expanded',String(open));});
$('#back').addEventListener('click',()=>history.back());$('#forward').addEventListener('click',()=>history.forward());
$('#logout').addEventListener('click',async()=>{try{await api('logout',{});audio.pause();location.replace('login.asp');}catch(error){toast(error.message);}});
$('#search-form').addEventListener('submit',event=>{event.preventDefault();if(location.hash!=='#search')location.hash='search';else renderSearch();});
$('#global-search').addEventListener('input',()=>{clearTimeout(searchTimer);searchTimer=setTimeout(()=>{if(!catalog)return;if(location.hash!=='#search')location.hash='search';else renderSearch();},200);});
document.addEventListener('keydown',event=>{if(event.key==='/'&&!/INPUT|TEXTAREA|SELECT/.test(document.activeElement.tagName)){event.preventDefault();$('#global-search').focus();}if(event.key==='Escape'){closeQueue();$('#sidebar').classList.remove('is-open');$('#menu-toggle').setAttribute('aria-expanded','false');}});
document.addEventListener('click',event=>{
    const play=event.target.closest('[data-play]');if(play&&catalog){playSong(songById(play.dataset.play),queueForContext(play.dataset.context));return;}
    const collection=event.target.closest('[data-play-collection]');if(collection&&catalog){playCollection(collection.dataset.playCollection);return;}
    const queueButton=event.target.closest('[data-queue-index]');if(queueButton&&catalog){playSong(queue[Number(queueButton.dataset.queueIndex)],null,true);return;}
    const explore=event.target.closest('[data-explore]');if(explore)location.hash=explore.dataset.explore;
    const edit=event.target.closest('[data-edit]');if(edit)openEditor(Number(edit.dataset.edit)).catch(error=>toast(error.message));
    const remove=event.target.closest('[data-delete]');if(remove)confirmDelete(Number(remove.dataset.delete));
    const add=event.target.closest('[data-add]');if(add)openEditor(0).catch(error=>toast(error.message));
    if(event.target.closest('#sidebar a')){$('#sidebar').classList.remove('is-open');$('#menu-toggle').setAttribute('aria-expanded','false');}
});
// Administration uses the same server-enforced role checks as direct API requests.
async function loadAdmin(type,version){
    if(Number(catalog.user.role)!==1){content.innerHTML=empty('Acceso restringido','Esta sección está disponible para administradores.');return;}
    adminEntity=entityLabels[type]?type:'users';
    const response=await api('admin-list',null,`&entity=${adminEntity}`);if(version!==routeVersion)return;
    adminItems=response.items;adminRelations=response.relations;renderAdmin();
}
function renderAdmin(){
    content.innerHTML=intro('Todo en sintonía.','Gestiona el catálogo y las cuentas de PoliMusic.','PANEL DE ADMINISTRACIÓN')+
    `<div class="admin-stats">${Object.entries(entityLabels).map(([key,label])=>`<a class="stat" href="#admin/${key}"><span>${label}</span><strong>${key==='users'?(adminEntity==='users'?adminItems.length:'—'):catalog[key].length}</strong></a>`).join('')}</div>
    <nav class="admin-tabs" aria-label="Entidades de administración">${Object.entries(entityLabels).map(([key,label])=>`<a href="#admin/${key}" class="${adminEntity===key?'active':''}">${label}</a>`).join('')}</nav>
    <div class="admin-toolbar"><input id="admin-search" type="search" placeholder="Buscar en ${entityLabels[adminEntity].toLowerCase()}…" aria-label="Filtrar registros"><button class="button primary" data-add>${icon('plus')}Agregar ${singular[adminEntity]}</button></div><div id="admin-records"></div><p class="admin-hint">Los cambios se guardan directamente en SQL Server. Las imágenes y el audio se eligen de los recursos locales. Al eliminar un registro también se eliminan sus relaciones.</p>`;
    renderAdminTable(adminItems);$('#admin-search').addEventListener('input',event=>{const term=event.target.value;renderAdminTable(adminItems.filter(item=>Object.values(item).some(v=>matches(v,term))));});
}
function renderAdminTable(items){
    const label=adminEntity==='users'?'Usuario':adminEntity==='artists'?'Artista':'Título';
    $('#admin-records').innerHTML=items.length?`<div class="table-wrap"><table class="admin-table"><thead><tr><th>ID</th><th>${label}</th><th>Información</th><th>Acciones</th></tr></thead><tbody>${items.map(item=>{
        const title=item.title||item.username||artistName(item);
        const info=adminEntity==='users'?`<span class="role-badge">${Number(item.role)===1?'Administrador':'Usuario'}</span>`:adminEntity==='songs'?`${Number(item.plays)} reproducciones`:adminEntity==='albums'?escapeHTML(item.year||'Sin año'):adminEntity==='playlists'?`<span class="role-badge">${Number(item.privacy)===1?'Privada':'Pública'}</span>`:'Artista';
        return `<tr><td>${Number(item.id)}</td><td><span class="record-title">${escapeHTML(title)}</span>${item.email?`<small>${escapeHTML(item.email)}</small>`:''}</td><td>${info}</td><td><div class="table-actions"><button class="icon-button" data-edit="${Number(item.id)}" aria-label="Editar ${escapeHTML(title)}">${icon('edit')}</button><button class="icon-button" data-delete="${Number(item.id)}" aria-label="Eliminar ${escapeHTML(title)}">${icon('trash')}</button></div></td></tr>`;
    }).join('')}</tbody></table></div>`:empty('Sin registros','Agrega un registro o cambia el filtro de búsqueda.');
}
function inputField(name,label,value='',type='text',max=255,required=false,hint=''){return `<label for="field-${name}">${escapeHTML(label)}</label><input id="field-${name}" name="${name}" type="${type}" value="${escapeHTML(value)}" maxlength="${max}" ${required?'required':''} ${type==='number'?'min="0" max="2147483647"':''} ${type==='password'?'autocomplete="new-password"':''}>${hint?`<p class="field-hint">${escapeHTML(hint)}</p>`:''}`;}
function selectField(name,label,options,value){return `<label for="field-${name}">${escapeHTML(label)}</label><select id="field-${name}" name="${name}">${options.map(([id,title])=>`<option value="${escapeHTML(id)}" ${String(id)===String(value)?'selected':''}>${escapeHTML(title)}</option>`).join('')}</select>`;}
function relationField(name,label,items,selected){return `<label>${escapeHTML(label)}</label><div class="relation-box">${items.length?items.map(item=>`<label><input type="checkbox" name="${name}" value="${item.id}" ${selected.includes(Number(item.id))?'checked':''}>${escapeHTML(item.title||artistName(item))}</label>`).join(''):'<p class="field-hint">No hay registros disponibles.</p>'}</div>`;}
function fileField(kind,value){
    const folders={song:'SongFiles',album:'AlbumImages',artist:'ArtistImages',playlist:'PlaylistImages',user:'UserImages'},files=resources.filter(p=>p.includes('/'+folders[kind]+'/'));
    const options=[['',kind==='song'?'Selecciona un archivo':'Usar portada predeterminada'],...files.map(path=>[path,path.split('/').pop()])];
    const normalized=String(value||'').replace(/^~\//,'SongFilesAndImages_resources/');
    if(kind==='song'&&value&&!files.some(path=>path.toLowerCase()===normalized.toLowerCase()))options.push([value,`${value} (archivo ausente)`]);
    const selected=files.find(path=>path.toLowerCase()===normalized.toLowerCase())||(kind==='song'?value:'')||'';
    return selectField(kind==='song'?'path':'image',kind==='song'?'Archivo de audio':'Imagen',options,selected)+`<p class="field-hint">${kind==='song'?'Archivos en SongFilesAndImages_resources/SongFiles.':'Si no hay una imagen, se usará una portada de PoliMusic.'}</p>`;
}
async function openEditor(id){
    const resourceData=await api('resources');resources=resourceData.files;users=resourceData.users;
    editorId=id;const item=adminItems.find(i=>Number(i.id)===id)||{},isNew=!id;
    $('#editor-title').textContent=`${isNew?'Agregar':'Editar'} ${singular[adminEntity]}`;$('#editor-error').textContent='';
    let fields='';
    if(adminEntity==='users')fields=inputField('username','Nombre de usuario',item.username||'','text',50,true)+inputField('email','Correo electrónico',item.email||'','email',50,true)+inputField('password',isNew?'Contraseña':'Nueva contraseña (opcional)','','password',128,isNew,'Mínimo 10 caracteres. Deja vacío para conservar la contraseña actual.')+selectField('role','Rol',[[0,'Usuario'],[1,'Administrador']],item.role??0)+inputField('birthday','Fecha de nacimiento',item.birthday||'','date',10)+fileField('user',item.image);
    if(adminEntity==='songs'){
        const artistIds=(adminRelations.artists||[]).filter(r=>Number(r.songId)===id).map(r=>Number(r.artistId)),albumIds=(adminRelations.albums||[]).filter(r=>Number(r.songId)===id).map(r=>Number(r.albumId));
        fields=inputField('title','Nombre de la canción',item.title||'','text',50,true)+fileField('song',item.path)+inputField('plays','Reproducciones',item.plays??0,'number')+relationField('artistIds','Artistas',catalog.artists,artistIds)+relationField('albumIds','Álbumes',catalog.albums,albumIds);
    }
    if(adminEntity==='artists')fields=inputField('name','Nombre',item.name||'','text',100,true)+inputField('lastname','Apellido',item.lastname||'','text',100)+fileField('artist',item.image);
    if(adminEntity==='albums')fields=inputField('title','Título del álbum',item.title||'','text',50,true)+inputField('year','Año de lanzamiento',item.year||'','number')+fileField('album',item.image)+relationField('songIds','Canciones',catalog.songs,(adminRelations.songs||[]).filter(r=>Number(r.albumId)===id).map(r=>Number(r.songId)));
    if(adminEntity==='playlists')fields=inputField('title','Título de la playlist',item.title||'','text',50,true)+selectField('ownerId','Propietario',users.map(u=>[u.id,u.username]),item.ownerId||catalog.user.id)+selectField('privacy','Visibilidad',[[0,'Pública'],[1,'Privada']],item.privacy??0)+fileField('playlist',item.image)+relationField('songIds','Canciones',catalog.songs,(adminRelations.songs||[]).filter(r=>Number(r.playlistId)===id).map(r=>Number(r.songId)));
    $('#editor-fields').innerHTML=fields;$('#editor').showModal();
}
$('#editor-close').addEventListener('click',()=>$('#editor').close());$('#editor-cancel').addEventListener('click',()=>$('#editor').close());
$('#editor-form').addEventListener('submit',async event=>{
    event.preventDefault();const button=$('#editor-save');button.disabled=true;$('#editor-error').textContent='';
    try{
        const data=new FormData(event.currentTarget),body={entity:adminEntity,id:editorId};
        for(const[key,value]of data.entries())body[key]=value;
        for(const relation of ['songIds','artistIds','albumIds'])body[relation]=data.getAll(relation).join(',');
        await api('admin-save',body);$('#editor').close();await refreshCatalog();await route();toast('Cambios guardados. Todo está en sintonía.');
    }catch(error){$('#editor-error').textContent=error.message;}finally{button.disabled=false;}
});
function confirmDelete(id){deleteId=id;const item=adminItems.find(i=>Number(i.id)===id);$('#confirmation-text').textContent=`¿Quieres eliminar “${item.title||item.username||artistName(item)}”?`;$('#confirmation-error').textContent='';$('#confirmation').showModal();}
$('#delete-cancel').addEventListener('click',()=>$('#confirmation').close());
$('#delete-confirm').addEventListener('click',async()=>{
    const button=$('#delete-confirm');button.disabled=true;
    try{await api('admin-delete',{entity:adminEntity,id:deleteId});$('#confirmation').close();await refreshCatalog();await route();toast('Registro eliminado.');}
    catch(error){$('#confirmation-error').textContent=error.message;}finally{button.disabled=false;}
});
async function refreshCatalog(){
    catalog=await api('catalog');csrf=catalog.csrf;
    $('#sidebar-playlists').innerHTML=catalog.playlists.slice(0,4).map(p=>`<a href="#playlists/${p.id}">${escapeHTML(p.title)}</a>`).join('');
    if(current){const refreshed=songById(current.id);if(!refreshed||!refreshed.available){audio.pause();audio.removeAttribute('src');audio.load();current=null;queue=[];$('#now-title').textContent='Tu música empieza aquí';$('#now-artist').textContent='Elige una canción y dale play';}else current=refreshed;}
    queue=queue.map(s=>songById(s.id)).filter(s=>s?.available);syncPlayUI();renderQueue();
}
async function route(){
    if(!catalog)return;const version=++routeVersion,[page='home',id]=(location.hash.slice(1)||'home').split('/');
    $$('[data-nav]').forEach(link=>{const active=link.dataset.nav===page;link.classList.toggle('active',active);if(active)link.setAttribute('aria-current','page');else link.removeAttribute('aria-current');});
    const title=page==='home'?'Inicio':page==='search'?'Explorar':page==='admin'?'Administración':entityLabels[page]||'Inicio';document.title=`${title} · PoliMusic`;
    try{
        if(page==='home')renderHome();
        else if(page==='search')renderSearch();
        else if(page==='songs')content.innerHTML=intro('Una canción, mil momentos.','Todo el catálogo de PoliMusic, a un play de distancia.','CANCIONES')+songTable(catalog.songs);
        else if(['albums','artists','playlists'].includes(page)){
            if(id)renderCollection(page,id);
            else content.innerHTML=intro(page==='albums'?'Historias que suenan.':page==='artists'?'Detrás de cada canción.':'El mood perfecto para ti.',page==='albums'?'Explora cada álbum, de la primera a la última nota.':page==='artists'?'Conoce a las voces que dan vida a tu música.':'Tus playlists y las colecciones públicas, en un solo lugar.',entityLabels[page].toUpperCase())+cards(catalog[page],page);
        }
        else if(page==='admin')await loadAdmin(id,version);
        else{location.hash='home';return;}
        syncPlayUI();
    }catch(error){if(version===routeVersion)content.innerHTML=`<div class="error-state"><h2>No pudimos cargar esta sección.</h2><p>${escapeHTML(error.message)}</p><button class="button primary" id="retry">Volver a intentar</button></div>`;$('#retry')?.addEventListener('click',route);}
}
window.addEventListener('hashchange',()=>{route();window.scrollTo({top:0,behavior:'instant'});});
async function start(){try{await refreshCatalog();await route();}catch(error){content.innerHTML=`<div class="error-state"><h2>Tu música nos espera.</h2><p>${escapeHTML(error.message)}</p><button id="retry" class="button primary">Volver a intentar</button></div>`;$('#retry').addEventListener('click',start);}}
start();
