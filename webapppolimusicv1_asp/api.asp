<%@ Language="JScript" CodePage="65001" %>
<!--#include file="includes/core.asp"-->
<%
Response.ContentType='application/json';
var inTransaction=false;
function begin(){db().BeginTrans();inTransaction=true;}
function commit(){db().CommitTrans();inTransaction=false;}
function ensureUnique(username,email,id){if(Number(scalar('SELECT COUNT(*) AS n FROM TBL_USER WITH (UPDLOCK,HOLDLOCK) WHERE (USERNAME=? OR EMAIL=?) AND ID_USER<>?',[username,email,id]))>0)abort(409,'Ya existe una cuenta con ese usuario o correo.');}
function authenticate(){
    requirePost();
    var username=required(form('username'),'Usuario',50),password=form('password'),ip=String(Request.ServerVariables('REMOTE_ADDR')).substr(0,100),key=Crypto.sha256(ip);
    if(password.length>128)abort(400,'Credenciales no válidas.');
    execute("IF NOT EXISTS(SELECT 1 FROM PM_LOGIN_LIMIT WHERE ATTEMPT_KEY=?) INSERT PM_LOGIN_LIMIT(ATTEMPT_KEY,FAILURES,WINDOW_START) VALUES(?,0,GETUTCDATE())",[key,key]);
    var limits=rows('SELECT FAILURES AS failures,DATEDIFF(second,WINDOW_START,GETUTCDATE()) AS elapsed FROM PM_LOGIN_LIMIT WHERE ATTEMPT_KEY=?',[key])[0];
    if(Number(limits.elapsed)>900)execute('UPDATE PM_LOGIN_LIMIT SET FAILURES=0,WINDOW_START=GETUTCDATE() WHERE ATTEMPT_KEY=?',[key]);
    else if(Number(limits.failures)>=8)abort(429,'Demasiados intentos. Inténtalo de nuevo en 15 minutos.');
    var found=rows('SELECT u.ID_USER AS id,c.SALT AS salt,c.PASSWORD_HASH AS hash,c.ITERATIONS AS iterations FROM TBL_USER u JOIN PM_CREDENTIAL c ON u.ID_USER=c.ID_USER WHERE u.USERNAME=?',[username]);
    // A dummy derivation avoids disclosing whether the username exists through timing.
    var salt=found.length?String(found[0].salt):'00000000000000000000000000000000';
    var derived=derivePassword(password,salt,found.length?Number(found[0].iterations):600000);
    if(!found.length||!Crypto.equal(derived,String(found[0].hash))){execute('UPDATE PM_LOGIN_LIMIT SET FAILURES=FAILURES+1 WHERE ATTEMPT_KEY=?',[key]);abort(401,'Usuario o contraseña incorrectos.');}
    execute('DELETE FROM PM_LOGIN_LIMIT WHERE ATTEMPT_KEY=?',[key]);
    // The authenticated ticket is random and replaces the anonymous session on login.
    var ticket=randomToken();execute('DELETE FROM PM_AUTH_TICKET WHERE EXPIRES_AT<GETUTCDATE()');
    execute('INSERT PM_AUTH_TICKET(TOKEN,ID_USER,EXPIRES_AT) VALUES(?,?,DATEADD(minute,1,GETUTCDATE()))',[ticket,Number(found[0].id)]);
    Session.Abandon();
    authCookie('PM_LOGIN',ticket,60);
    return {ok:true,redirect:'welcome.asp'};
}
function register(){
    requirePost();var username=usernameValue(form('username')),email=emailValue(form('email')),password=passwordValue(form('password'));
    if(password!==form('confirm'))abort(400,'Las contraseñas no coinciden.');
    // Registration is always role 0; no posted role is accepted.
    begin();ensureUnique(username,email,0);
    var id=Number(scalar("INSERT TBL_USER(USERNAME,PASSWORD,EMAIL,USER_TYPE,USER_PHOTO) OUTPUT INSERTED.ID_USER VALUES(?,'[PBKDF2]',?,0,'')",[username,email]));
    setPassword(id,password);commit();return {ok:true,message:'Cuenta creada. Ya puedes iniciar sesión.'};
}
function catalog(user){
    var songs=rows('SELECT ID_SONG AS id,SONG_NAME AS title,SONG_PATH AS path,ISNULL(PLAYS,0) AS plays FROM TBL_SONG ORDER BY ID_SONG');
    var artists=rows("SELECT ID_ARTIST AS id,ARTIST_NAME AS name,ISNULL(ARTIST_LASTNAME,'') AS lastname,ARTIST_IMAGE AS image FROM TBL_ARTIST ORDER BY ARTIST_NAME");
    var albums=rows('SELECT ID_ALBUM AS id,TITLE_ALBUM AS title,RELEASE_YEAR AS year,ALBUM_IMAGE_PATH AS image FROM TBL_ALBUM ORDER BY RELEASE_YEAR DESC');
    var playlists=rows('SELECT ID_PLAYLIST AS id,ID_USER AS ownerId,TITLE AS title,TYPE AS privacy,PHOTO AS image FROM TBL_PLAYLIST WHERE TYPE=0 OR ID_USER=? OR ?=1 ORDER BY ID_PLAYLIST',[Number(user.id),Number(user.role)]);
    var player=rows('SELECT ID_SONG AS songId,ID_ARTIST AS artistId FROM TBL_PLAYER'),tracks=rows('SELECT ID_ALBUM AS albumId,ID_SONG AS songId FROM TBL_TRACKLIST');
    var playlistSongs=rows('SELECT ps.ID_PLAYLIST AS playlistId,ps.ID_SONG AS songId FROM TBL_PLAYLIST_SONG ps JOIN TBL_PLAYLIST p ON p.ID_PLAYLIST=ps.ID_PLAYLIST WHERE p.TYPE=0 OR p.ID_USER=? OR ?=1',[Number(user.id),Number(user.role)]);
    var i,j;
    for(i=0;i<songs.length;i++){var song=songs[i];song.available=!!assetPath(song.path,'song');song.artistIds=[];song.albumIds=[];for(j=0;j<player.length;j++)if(Number(player[j].songId)===Number(song.id))song.artistIds.push(Number(player[j].artistId));for(j=0;j<tracks.length;j++)if(Number(tracks[j].songId)===Number(song.id))song.albumIds.push(Number(tracks[j].albumId));song.image='assets/cover-'+(Number(song.id)%5)+'.svg';delete song.path;}
    for(i=0;i<artists.length;i++){artists[i].image=imagePath(artists[i].image,'artist',artists[i].id);artists[i].songIds=[];for(j=0;j<player.length;j++)if(Number(player[j].artistId)===Number(artists[i].id))artists[i].songIds.push(Number(player[j].songId));}
    for(i=0;i<albums.length;i++){albums[i].image=imagePath(albums[i].image,'album',albums[i].id);albums[i].songIds=[];for(j=0;j<tracks.length;j++)if(Number(tracks[j].albumId)===Number(albums[i].id))albums[i].songIds.push(Number(tracks[j].songId));}
    for(i=0;i<playlists.length;i++){playlists[i].image=imagePath(playlists[i].image,'playlist',playlists[i].id);playlists[i].songIds=[];for(j=0;j<playlistSongs.length;j++)if(Number(playlistSongs[j].playlistId)===Number(playlists[i].id))playlists[i].songIds.push(Number(playlistSongs[j].songId));}
    return {user:user,songs:songs,artists:artists,albums:albums,playlists:playlists,csrf:csrf()};
}
var entities={users:{table:'TBL_USER',pk:'ID_USER'},songs:{table:'TBL_SONG',pk:'ID_SONG'},artists:{table:'TBL_ARTIST',pk:'ID_ARTIST'},albums:{table:'TBL_ALBUM',pk:'ID_ALBUM'},playlists:{table:'TBL_PLAYLIST',pk:'ID_PLAYLIST'}};
function entity(){var name=form('entity')||query('entity');if(!entities.hasOwnProperty(name))abort(400,'Entidad no válida.');return {name:name,table:entities[name].table,pk:entities[name].pk};}
function listAdmin(){
    requireAdmin();var e=entity(),list;
    if(e.name==='users')list=rows('SELECT ID_USER AS id,USERNAME AS username,EMAIL AS email,USER_TYPE AS role,CONVERT(varchar(10),BIRTHDAY,23) AS birthday,USER_PHOTO AS image FROM TBL_USER ORDER BY ID_USER');
    if(e.name==='songs')list=rows('SELECT ID_SONG AS id,SONG_NAME AS title,SONG_PATH AS path,ISNULL(PLAYS,0) AS plays FROM TBL_SONG ORDER BY ID_SONG');
    if(e.name==='artists')list=rows("SELECT ID_ARTIST AS id,ARTIST_NAME AS name,ISNULL(ARTIST_LASTNAME,'') AS lastname,ARTIST_IMAGE AS image FROM TBL_ARTIST ORDER BY ID_ARTIST");
    if(e.name==='albums')list=rows('SELECT ID_ALBUM AS id,TITLE_ALBUM AS title,RELEASE_YEAR AS year,ALBUM_IMAGE_PATH AS image FROM TBL_ALBUM ORDER BY ID_ALBUM');
    if(e.name==='playlists')list=rows('SELECT ID_PLAYLIST AS id,ID_USER AS ownerId,TITLE AS title,TYPE AS privacy,PHOTO AS image FROM TBL_PLAYLIST ORDER BY ID_PLAYLIST');
    var extra={};if(e.name==='songs'){extra.artists=rows('SELECT ID_SONG AS songId,ID_ARTIST AS artistId FROM TBL_PLAYER');extra.albums=rows('SELECT ID_ALBUM AS albumId,ID_SONG AS songId FROM TBL_TRACKLIST');}
    if(e.name==='albums')extra.songs=rows('SELECT ID_ALBUM AS albumId,ID_SONG AS songId FROM TBL_TRACKLIST');
    if(e.name==='playlists')extra.songs=rows('SELECT ID_PLAYLIST AS playlistId,ID_SONG AS songId FROM TBL_PLAYLIST_SONG');
    return {items:list,relations:extra};
}
function replaceLinks(table,parentColumn,childColumn,parent,ids,childTable,childPk){execute('DELETE FROM '+table+' WHERE '+parentColumn+'=?',[parent]);for(var i=0;i<ids.length;i++){if(!scalar('SELECT '+childPk+' FROM '+childTable+' WHERE '+childPk+'=?',[ids[i]]))abort(400,'Una relación seleccionada ya no existe.');execute('INSERT '+table+'('+parentColumn+','+childColumn+') VALUES(?,?)',[parent,ids[i]]);}}
function protectAdmin(id,newRole,user){
    if(id===Number(user.id)&&(newRole!==1))abort(400,'No puedes eliminar tu cuenta ni quitarte el rol de administrador.');
    var old=scalar('SELECT USER_TYPE FROM TBL_USER WITH (UPDLOCK,HOLDLOCK) WHERE ID_USER=?',[id]);
    if(Number(old)===1&&newRole!==1&&Number(scalar('SELECT COUNT(*) AS n FROM TBL_USER WITH (UPDLOCK,HOLDLOCK) WHERE USER_TYPE=1'))<=1)abort(400,'Debe existir al menos un administrador.');
}
function saveAdmin(){
    var user=requireAdmin();requirePost();var e=entity(),id=integer(form('id')||'0','Identificador'),isNew=id===0,values,cols;
    begin();if(!isNew&&!scalar('SELECT '+e.pk+' FROM '+e.table+' WITH(UPDLOCK,HOLDLOCK) WHERE '+e.pk+'=?',[id]))abort(404,'El registro ya no existe.');
    if(e.name==='users'){
        var username=usernameValue(form('username')),email=emailValue(form('email')),role=integer(form('role'),'Rol',0,1),password=form('password');
        ensureUnique(username,email,id);if(!isNew)protectAdmin(id,role,user);if(isNew||password)passwordValue(password);
        var birthday=form('birthday');if(birthday){var dateParts=/^(\d{4})-(\d{2})-(\d{2})$/.exec(birthday),birthDate=dateParts?new Date(Number(dateParts[1]),Number(dateParts[2])-1,Number(dateParts[3])):null;if(!birthDate||birthDate.getFullYear()!==Number(dateParts[1])||birthDate.getMonth()!==Number(dateParts[2])-1||birthDate.getDate()!==Number(dateParts[3])||birthDate.getTime()>new Date().getTime())abort(400,'Fecha de nacimiento no válida.');birthday=birthday.replace(/-/g,'');}
        cols=['USERNAME','EMAIL','USER_TYPE','BIRTHDAY','USER_PHOTO'];values=[username,email,role,birthday||null,validatePath(form('image'),'user',true)];
        if(isNew){cols.push('PASSWORD');values.push('[PBKDF2]');}
    }
    if(e.name==='songs'){cols=['SONG_NAME','SONG_PATH'];var path=form('path'),oldPath=isNew?'':textValue(scalar('SELECT SONG_PATH FROM TBL_SONG WHERE ID_SONG=?',[id]));if(path!==oldPath||isNew)path=validatePath(path,'song',false);cols.push('PLAYS');values=[required(form('title'),'Nombre de canción',50),path,integer(form('plays')||'0','Reproducciones')];}
    if(e.name==='artists'){cols=['ARTIST_NAME','ARTIST_LASTNAME','ARTIST_IMAGE'];values=[required(form('name'),'Nombre de artista',100),form('lastname').substr(0,100),validatePath(form('image'),'artist',true)];}
    if(e.name==='albums'){cols=['TITLE_ALBUM','RELEASE_YEAR','ALBUM_IMAGE_PATH'];values=[required(form('title'),'Título del álbum',50),form('year')?integer(form('year'),'Año',1000,new Date().getFullYear()+2):null,validatePath(form('image'),'album',true)];}
    if(e.name==='playlists'){var owner=integer(form('ownerId'),'Propietario',1);if(!scalar('SELECT ID_USER FROM TBL_USER WHERE ID_USER=?',[owner]))abort(400,'Selecciona un propietario existente.');cols=['ID_USER','TITLE','TYPE','PHOTO'];values=[owner,required(form('title'),'Título de playlist',50),integer(form('privacy'),'Visibilidad',0,1),validatePath(form('image'),'playlist',true)];if(isNew){cols.push('CREATION_DATE');values.push(String(new Date().getFullYear())+'-01-01');}}
    var placeholders=[],assignments=[],i;for(i=0;i<cols.length;i++){placeholders.push('?');assignments.push(cols[i]+'=?');}
    if(isNew){if(e.name==='playlists'){cols.pop();values.pop();placeholders.pop();id=Number(scalar('INSERT '+e.table+'('+cols.join(',')+',CREATION_DATE) OUTPUT INSERTED.'+e.pk+' VALUES('+placeholders.join(',')+',GETDATE())',values));}else id=Number(scalar('INSERT '+e.table+'('+cols.join(',')+') OUTPUT INSERTED.'+e.pk+' VALUES('+placeholders.join(',')+')',values));}
    else{values.push(id);execute('UPDATE '+e.table+' SET '+assignments.join(',')+' WHERE '+e.pk+'=?',values);}
    if(e.name==='users'&&(isNew||password))setPassword(id,password);
    if(e.name==='songs'){replaceLinks('TBL_PLAYER','ID_SONG','ID_ARTIST',id,idList(form('artistIds'),'Artista'),'TBL_ARTIST','ID_ARTIST');replaceLinks('TBL_TRACKLIST','ID_SONG','ID_ALBUM',id,idList(form('albumIds'),'Álbum'),'TBL_ALBUM','ID_ALBUM');}
    if(e.name==='albums')replaceLinks('TBL_TRACKLIST','ID_ALBUM','ID_SONG',id,idList(form('songIds'),'Canción'),'TBL_SONG','ID_SONG');
    if(e.name==='playlists')replaceLinks('TBL_PLAYLIST_SONG','ID_PLAYLIST','ID_SONG',id,idList(form('songIds'),'Canción'),'TBL_SONG','ID_SONG');
    commit();return {ok:true,id:id};
}
function deleteAdmin(){
    var user=requireAdmin();requirePost();var e=entity(),id=integer(form('id'),'Identificador',1);begin();
    if(!scalar('SELECT '+e.pk+' FROM '+e.table+' WITH(UPDLOCK,HOLDLOCK) WHERE '+e.pk+'=?',[id]))abort(404,'El registro ya no existe.');
    if(e.name==='users'){protectAdmin(id,-1,user);execute('DELETE ps FROM TBL_PLAYLIST_SONG ps JOIN TBL_PLAYLIST p ON p.ID_PLAYLIST=ps.ID_PLAYLIST WHERE p.ID_USER=?',[id]);execute('DELETE TBL_PLAYLIST WHERE ID_USER=?',[id]);execute('DELETE PM_CREDENTIAL WHERE ID_USER=?',[id]);execute('DELETE PM_AUTH_TICKET WHERE ID_USER=?',[id]);}
    if(e.name==='songs'){execute('DELETE TBL_PLAYER WHERE ID_SONG=?',[id]);execute('DELETE TBL_TRACKLIST WHERE ID_SONG=?',[id]);execute('DELETE TBL_PLAYLIST_SONG WHERE ID_SONG=?',[id]);}
    if(e.name==='artists')execute('DELETE TBL_PLAYER WHERE ID_ARTIST=?',[id]);
    if(e.name==='albums')execute('DELETE TBL_TRACKLIST WHERE ID_ALBUM=?',[id]);
    if(e.name==='playlists')execute('DELETE TBL_PLAYLIST_SONG WHERE ID_PLAYLIST=?',[id]);
    execute('DELETE '+e.table+' WHERE '+e.pk+'=?',[id]);commit();return {ok:true};
}
try{
    var action=query('action'),result;
    if(action==='session')result={user:currentUser(),csrf:csrf()};
    else if(action==='login')result=authenticate();
    else if(action==='register')result=register();
    else if(action==='logout'){requirePost();Session.Abandon();authCookie('PM_AUTH','',0);result={ok:true};}
    else if(action==='catalog')result=catalog(requireUser());
    else if(action==='admin-list')result=listAdmin();
    else if(action==='admin-save')result=saveAdmin();
    else if(action==='admin-delete')result=deleteAdmin();
    else if(action==='resources'){
        requireAdmin();var files=[],folders=['SongFiles','PlaylistImages','UserImages','ArtistImages','AlbumImages'];
        for(var k=0;k<folders.length;k++){var folder='SongFilesAndImages_resources/'+folders[k];if(fileSystem.FolderExists(Server.MapPath(folder))){var en=new Enumerator(fileSystem.GetFolder(Server.MapPath(folder)).Files);for(;!en.atEnd();en.moveNext())files.push(folder+'/'+String(en.item().Name));}}result={files:files,users:rows('SELECT ID_USER AS id,USERNAME AS username FROM TBL_USER ORDER BY USERNAME')};
    }
    else if(action==='play'){requireUser();requirePost();var sid=integer(form('id'),'Canción',1),path=scalar('SELECT SONG_PATH FROM TBL_SONG WHERE ID_SONG=?',[sid]);if(!assetPath(path,'song'))abort(404,'El archivo de audio no está disponible.');execute('UPDATE TBL_SONG SET PLAYS=ISNULL(PLAYS,0)+1 WHERE ID_SONG=?',[sid]);result={ok:true};}
    else abort(404,'Operación no encontrada.');
    Response.Write(json(result));
}catch(e){
    if(inTransaction){try{db().RollbackTrans();}catch(ignore){}}
    var status=e.httpStatus||503;Response.Status=status+' '+({400:'Bad Request',401:'Unauthorized',403:'Forbidden',404:'Not Found',405:'Method Not Allowed',409:'Conflict',429:'Too Many Requests',503:'Service Unavailable'}[status]||'Error');
    var message=e.httpStatus?e.message:'No se pudo completar la operación. Comprueba la configuración de la base de datos e inténtalo de nuevo.';
    Response.Write(json({error:message}));
}finally{closeDb();}
%>
