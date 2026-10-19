<%@ Language="JScript" CodePage="65001" %>
<!--#include file="includes/core.asp"-->
<%
try{
    var ticket=String(Request.Cookies('PM_LOGIN'));
    if(/^[A-F0-9]{64}$/.test(ticket)){
        db().BeginTrans();
        var users=rows('SELECT ID_USER AS id FROM PM_AUTH_TICKET WITH(UPDLOCK,HOLDLOCK) WHERE TOKEN=? AND EXPIRES_AT>GETUTCDATE()',[ticket]);
        execute('DELETE PM_AUTH_TICKET WHERE TOKEN=?',[ticket]);db().CommitTrans();
        if(users.length){Session('uid')=Number(users[0].id);Session('csrf')=randomToken();var binding=randomToken();Session('authKey')=binding;authCookie('PM_AUTH',binding,1800);}
    }
    authCookie('PM_LOGIN','',0);
    closeDb();Response.Redirect('default.asp');
}catch(e){closeDb();Response.Redirect('login.asp');}
%>
