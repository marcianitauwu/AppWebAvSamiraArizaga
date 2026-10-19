<!--#include file="crypto.asp"-->
<%
Response.Buffer = true;
Response.CodePage = 65001;
Response.Charset = "utf-8";
Server.ScriptTimeout = 240;
Session.Timeout = 30;
Response.AddHeader("X-Content-Type-Options", "nosniff");
Response.AddHeader("Referrer-Policy", "same-origin");
Response.AddHeader("X-Frame-Options", "DENY");
Response.AddHeader("Cache-Control", "no-store");
Response.AddHeader("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; media-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'");
var connection = null, fileSystem = Server.CreateObject("Scripting.FileSystemObject");
function textValue(v){return v===null||typeof v==='undefined'?'':String(v);}
function html(v){return Server.HTMLEncode(textValue(v));}
function json(v){
    if(v===null||typeof v==='undefined')return 'null';
    if(typeof v==='number')return isFinite(v)?String(v):'null';
    if(typeof v==='boolean')return v?'true':'false';
    if(typeof v==='string')return '"'+v.replace(/[\\"\x00-\x1f]/g,function(c){var m={'"':'\\"','\\':'\\\\','\n':'\\n','\r':'\\r','\t':'\\t'};return m[c]||'\\u'+('0000'+c.charCodeAt(0).toString(16)).slice(-4);})+'"';
    var a=[],i;
    if(v instanceof Array){for(i=0;i<v.length;i++)a.push(json(v[i]));return '['+a.join(',')+']';}
    for(i in v)if(v.hasOwnProperty(i))a.push(json(i)+':'+json(v[i]));return '{'+a.join(',')+'}';
}
function db(){
    if(connection===null){
        var path=Server.MapPath("App_Data/connection.txt");
        if(!fileSystem.FileExists(path))throw new Error('CONFIG_MISSING');
        var f=fileSystem.OpenTextFile(path,1),cs=f.ReadAll();f.Close();
        connection=Server.CreateObject('ADODB.Connection');connection.ConnectionTimeout=10;connection.CommandTimeout=30;connection.Open(cs);
    }return connection;
}
function command(sql,params){var c=Server.CreateObject('ADODB.Command');c.ActiveConnection=db();c.CommandType=1;c.CommandText=sql;params=params||[];for(var i=0;i<params.length;i++){var v=params[i],numeric=typeof v==='number',p=c.CreateParameter('p'+i,numeric?3:202,1,numeric?4:Math.max(1,String(v===null?'':v).length),v);c.Parameters.Append(p);}return c;}
function rows(sql,params){var r=command(sql,params).Execute(),list=[];while(!r.EOF){var row={};for(var i=0;i<r.Fields.Count;i++){var field=r.Fields.Item(i);row[String(field.Name)]=field.Value===null?null:field.Value;}list.push(row);r.MoveNext();}r.Close();return list;}
function execute(sql,params){command(sql,params).Execute();}
function scalar(sql,params){var r=rows(sql,params);if(!r.length)return null;for(var k in r[0])return r[0][k];return null;}
function randomToken(){return String(scalar("SELECT CONVERT(varchar(64),CRYPT_GEN_RANDOM(32),2) AS token"));}
function authCookie(name,value,maxAge){var path=String(Request.ServerVariables('APPL_VIRTUAL_PATH'))||'/';Response.AddHeader('Set-Cookie',name+'='+value+'; Path='+path+'; Max-Age='+maxAge+'; HttpOnly; SameSite=Lax'+(String(Request.ServerVariables('HTTPS'))==='on'?'; Secure':''));}
function csrf(){if(!Session('csrf'))Session('csrf')=randomToken();return String(Session('csrf'));}
function form(name){var values=Request.Form(name);return Number(values.Count)>0?textValue(values.Item(1)):'';}
function query(name){var values=Request.QueryString(name);return Number(values.Count)>0?textValue(values.Item(1)):'';}
function abort(status,message){var e=new Error(message);e.httpStatus=status;throw e;}
function requirePost(){if(String(Request.ServerVariables('REQUEST_METHOD'))!=='POST')abort(405,'Método no permitido.');if(!Crypto.equal(form('csrf'),csrf()))abort(403,'La sesión del formulario expiró. Recarga la página.');}
function currentUser(){
    var id=Number(Session('uid')||0);if(!id)return null;
    // A separate random HttpOnly token prevents a known ASP session ID from
    // becoming an authenticated session after another person signs in.
    var binding=String(Session('authKey')||''),cookie=String(Request.Cookies('PM_AUTH'));
    if(!/^[A-F0-9]{64}$/.test(binding)||binding!==cookie)return null;
    var users=rows('SELECT ID_USER AS id,USERNAME AS username,EMAIL AS email,USER_TYPE AS role,USER_PHOTO AS photo FROM TBL_USER WHERE ID_USER=?',[id]);
    if(!users.length){Session.Abandon();return null;}return users[0];
}
function requireUser(){var u=currentUser();if(!u)abort(401,'Inicia sesión para continuar.');return u;}
function requireAdmin(){var u=requireUser();if(Number(u.role)!==1)abort(403,'Solo el administrador puede realizar esta operación.');return u;}
function integer(value,label,min,max){var s=String(value);if(!/^\d+$/.test(s))abort(400,label+' no válido.');var n=Number(s);if(n<(min||0)||n>(max||2147483647))abort(400,label+' fuera de rango.');return n;}
function required(value,label,max){var s=String(value).replace(/^\s+|\s+$/g,'');if(!s||s.length>max)abort(400,label+': ingresa entre 1 y '+max+' caracteres.');return s;}
function emailValue(s){s=required(s,'Correo electrónico',50);if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s))abort(400,'Ingresa un correo electrónico válido.');return s;}
function usernameValue(s){s=required(s,'Usuario',50);if(!/^[a-zA-Z0-9._-]{3,50}$/.test(s))abort(400,'El usuario debe tener de 3 a 50 letras, números, puntos, guiones o guiones bajos.');return s;}
function passwordValue(s){if(s.length<10||s.length>128)abort(400,'La contraseña debe tener entre 10 y 128 caracteres.');return s;}
function derivePassword(password,salt,iterations){var nativeCrypto=null;try{nativeCrypto=Server.CreateObject('PoliMusic.Security');}catch(missing){}if(nativeCrypto!==null)return String(nativeCrypto.Pbkdf2(password,salt,iterations));throw new Error('SECURITY_COMPONENT_MISSING');}
function setPassword(id,password){var salt=randomToken().substr(0,32),iterations=600000,hash=derivePassword(password,salt,iterations);execute('DELETE FROM PM_CREDENTIAL WHERE ID_USER=?',[id]);execute('INSERT INTO PM_CREDENTIAL(ID_USER,SALT,PASSWORD_HASH,ITERATIONS) VALUES(?,?,?,?)',[id,salt,hash,iterations]);execute("UPDATE TBL_USER SET PASSWORD='[PBKDF2]' WHERE ID_USER=?",[id]);}
function assetPath(raw,kind){
    var p=textValue(raw).replace(/\\/g,'/').replace(/^~\//,'').replace(/^\/+/,''),folder=kind==='song'?'SongFiles':kind==='playlist'?'PlaylistImages':kind==='user'?'UserImages':kind==='artist'?'ArtistImages':'AlbumImages';
    if(!p||p.indexOf('..')>=0||p.indexOf(':')>=0||p.indexOf('%')>=0)return '';
    p=p.replace(/^SongFilesAndImages_resources\//i,'');
    var parts=p.split('/');if(parts.length!==2||parts[0].toLowerCase()!==folder.toLowerCase())return '';
    var extension=parts[1].split('.').pop().toLowerCase();if(kind==='song'?!/^(mp3|wav|ogg|m4a)$/.test(extension):!/^(jpg|jpeg|png|webp|gif|svg)$/.test(extension))return '';
    var full='SongFilesAndImages_resources/'+folder+'/'+parts[1];return fileSystem.FileExists(Server.MapPath(full))?full:'';
}
function imagePath(raw,kind,id){return assetPath(raw,kind)||'assets/cover-'+((Number(id)||0)%5)+'.svg';}
function validatePath(raw,kind,optional){var value=String(raw).replace(/^\s+|\s+$/g,'');if(optional&&!value)return '';if(!assetPath(value,kind))abort(400,'La ruta debe apuntar a un archivo existente en la carpeta de recursos correspondiente.');return value;}
function idList(value,label){if(!value)return [];var a=value.split(','),out=[],seen={};for(var i=0;i<a.length;i++){var n=integer(a[i],label,1);if(!seen[n]){out.push(n);seen[n]=true;}}if(out.length>500)abort(400,'Selecciona como máximo 500 elementos.');return out;}
function closeDb(){if(connection!==null){try{connection.Close();}catch(ignore){}connection=null;}}
%>
