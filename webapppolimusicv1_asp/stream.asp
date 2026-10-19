<%@ Language="JScript" CodePage="65001" %>
<!--#include file="includes/core.asp"-->
<%
var stream=null;
try{
    requireUser();var id=integer(query('id'),'Canción',1),path=assetPath(scalar('SELECT SONG_PATH FROM TBL_SONG WHERE ID_SONG=?',[id]),'song');
    if(!path)abort(404,'Audio no disponible.');closeDb();
    var file=fileSystem.GetFile(Server.MapPath(path)),size=Number(file.Size),start=0,end=size-1,range=String(Request.ServerVariables('HTTP_RANGE'));
    if(range){var m=/^bytes=(\d*)-(\d*)$/.exec(range);if(!m||(!m[1]&&!m[2]))abort(416,'Rango no válido.');if(!m[1])start=Math.max(0,size-Number(m[2]));else start=Number(m[1]);if(m[1]&&m[2])end=Math.min(end,Number(m[2]));if(start>end||start>=size)abort(416,'Rango no válido.');Response.Status='206 Partial Content';Response.AddHeader('Content-Range','bytes '+start+'-'+end+'/'+size);}
    Response.ContentType=/\.wav$/i.test(path)?'audio/wav':/\.ogg$/i.test(path)?'audio/ogg':/\.m4a$/i.test(path)?'audio/mp4':'audio/mpeg';
    Response.AddHeader('Accept-Ranges','bytes');Response.AddHeader('Content-Length',String(end-start+1));
    if(String(Request.ServerVariables('REQUEST_METHOD'))!=='HEAD'){
        stream=Server.CreateObject('ADODB.Stream');stream.Type=1;stream.Open();stream.LoadFromFile(Server.MapPath(path));stream.Position=start;
        var remaining=end-start+1;while(remaining>0&&Response.IsClientConnected){var chunk=Math.min(65536,remaining);Response.BinaryWrite(stream.Read(chunk));Response.Flush();remaining-=chunk;}
    }
}catch(e){Response.Status=(e.httpStatus||503)+' Error';if(e.httpStatus===416)Response.AddHeader('Content-Range','bytes */'+size);Response.ContentType='text/plain';Response.Write(e.httpStatus?e.message:'Audio no disponible.');}
finally{if(stream!==null)stream.Close();closeDb();}
%>
