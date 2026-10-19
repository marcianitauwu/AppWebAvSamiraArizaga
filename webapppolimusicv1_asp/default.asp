<%@ Language="JScript" CodePage="65001" %>
<!--#include file="includes/core.asp"-->
<%
var viewer=null;
try { viewer=currentUser(); } catch(e) { }
closeDb();
if(!viewer)Response.Redirect('login.asp');
%>
<!doctype html><html lang="es"><head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#15111d">
  <title>Inicio · PoliMusic</title><link rel="icon" href="assets/logo.svg?v=2" type="image/svg+xml">
  <link rel="stylesheet" href="assets/style.css?v=2"><script src="assets/app.js" defer></script>
</head><body class="app-page">
<a class="skip-link" href="#content">Saltar al contenido</a>
<aside class="sidebar" id="sidebar">
  <a class="brand" href="#home"><img src="assets/logo.svg?v=2" width="36" height="36" alt="">Poli<span>Music</span></a>
  <div class="nav-label">DESCUBRE TU SONIDO</div>
  <nav aria-label="Navegación principal">
    <a href="#home" data-nav="home"><svg class="icon"><use href="assets/icons.svg#home"/></svg>Inicio</a>
    <a href="#search" data-nav="search"><svg class="icon"><use href="assets/icons.svg#search"/></svg>Explorar</a>
    <a href="#songs" data-nav="songs"><svg class="icon"><use href="assets/icons.svg#music"/></svg>Canciones</a>
    <a href="#albums" data-nav="albums"><svg class="icon"><use href="assets/icons.svg#album"/></svg>Álbumes</a>
    <a href="#artists" data-nav="artists"><svg class="icon"><use href="assets/icons.svg#mic"/></svg>Artistas</a>
  </nav>
  <div class="nav-label library-label">TU BIBLIOTECA<svg class="icon"><use href="assets/icons.svg#library"/></svg></div>
  <nav aria-label="Biblioteca"><a href="#playlists" data-nav="playlists"><svg class="icon"><use href="assets/icons.svg#playlist"/></svg>Playlists</a></nav>
  <div id="sidebar-playlists" class="sidebar-playlists"></div>
  <% if(Number(viewer.role)===1){ %><div class="admin-nav"><div class="nav-label">ADMINISTRACIÓN</div><nav aria-label="Administración"><a href="#admin/users" data-nav="admin"><svg class="icon"><use href="assets/icons.svg#settings"/></svg>Panel de control<span class="mini-badge">ADMIN</span></a></nav></div><% } %>
  <div class="sidebar-bottom"><div class="sound-mark"><i></i><i></i><i></i><i></i><i></i></div><strong>La vida suena mejor.</strong><span>Dale play a tu momento.</span></div>
</aside>
<div class="workspace">
  <header class="topbar">
    <button class="icon-button mobile-menu" id="menu-toggle" aria-label="Abrir menú" aria-expanded="false" aria-controls="sidebar"><svg class="icon"><use href="assets/icons.svg#menu"/></svg></button>
    <div class="history-buttons"><button class="icon-button" id="back" aria-label="Volver"><svg class="icon"><use href="assets/icons.svg#chevron-left"/></svg></button><button class="icon-button" id="forward" aria-label="Avanzar"><svg class="icon"><use href="assets/icons.svg#chevron-right"/></svg></button></div>
    <form class="searchbar" id="search-form" role="search"><svg class="icon"><use href="assets/icons.svg#search"/></svg><input id="global-search" type="search" maxlength="100" aria-label="Buscar música" placeholder="¿Qué quieres escuchar hoy?"><kbd>/</kbd></form>
    <div class="profile"><span class="profile-avatar"><%=html(String(viewer.username).substr(0,1).toUpperCase())%></span><div><strong><%=html(viewer.username)%></strong><small><%=Number(viewer.role)===1?'Administrador':'Amante de la música'%></small></div><button class="icon-button" id="logout" aria-label="Cerrar sesión" title="Cerrar sesión"><svg class="icon"><use href="assets/icons.svg#logout"/></svg></button></div>
  </header>
  <main id="content" tabindex="-1"><div class="loading-state"><div class="sound-mark"><i></i><i></i><i></i><i></i><i></i></div><p>Preparando tu música…</p></div></main>
  <footer class="page-footer"><span>PoliMusic</span> La música nos conecta.<small>ASP clásico · Hecho con ritmo</small></footer>
</div>
<section class="player" aria-label="Reproductor de música">
  <div class="now-playing"><img id="now-cover" src="assets/cover-1.svg" width="52" height="52" alt="Portada"><div><strong id="now-title">Tu música empieza aquí</strong><span id="now-artist">Elige una canción y dale play</span></div></div>
  <div class="player-center"><div class="player-controls">
    <button class="icon-button" id="shuffle" aria-label="Activar reproducción aleatoria" aria-pressed="false" title="Aleatorio"><svg class="icon"><use href="assets/icons.svg#shuffle"/></svg></button>
    <button class="icon-button" id="previous" aria-label="Canción anterior"><svg class="icon"><use href="assets/icons.svg#previous"/></svg></button>
    <button class="play-main" id="toggle-play" aria-label="Reproducir"><svg class="icon"><use href="assets/icons.svg#play"/></svg></button>
    <button class="icon-button" id="next" aria-label="Siguiente canción"><svg class="icon"><use href="assets/icons.svg#next"/></svg></button>
    <button class="icon-button" id="repeat" aria-label="Repetir canción" aria-pressed="false" title="Repetir"><svg class="icon"><use href="assets/icons.svg#repeat"/></svg></button>
  </div><div class="timeline"><span id="elapsed">0:00</span><input id="seek" type="range" min="0" max="1000" value="0" aria-label="Posición de reproducción" disabled><span id="duration">0:00</span></div></div>
  <div class="player-options"><button class="icon-button" id="queue-toggle" aria-label="Ver cola de reproducción" aria-expanded="false" aria-controls="queue-panel"><svg class="icon"><use href="assets/icons.svg#playlist"/></svg></button><span class="player-divider"></span><button class="icon-button" id="mute" aria-label="Silenciar"><svg class="icon"><use href="assets/icons.svg#volume"/></svg></button><input id="volume" type="range" min="0" max="100" value="75" aria-label="Volumen"></div>
</section>
<aside id="queue-panel" class="queue-panel" aria-label="Cola de reproducción" hidden><div class="section-heading"><h2>A continuación</h2><button id="queue-close" class="icon-button" aria-label="Cerrar cola">×</button></div><div id="queue-list"></div></aside>
<audio id="audio" preload="metadata"></audio>
<div id="toast" class="toast" role="status" aria-live="polite" hidden></div>
<dialog id="editor" aria-labelledby="editor-title"><form id="editor-form"><div class="modal-heading"><div><div class="eyebrow">POLIMUSIC STUDIO</div><h2 id="editor-title">Editar registro</h2></div><button type="button" class="icon-button" id="editor-close" aria-label="Cerrar">×</button></div><div id="editor-fields"></div><p id="editor-error" class="form-message error" role="alert"></p><div class="modal-actions"><button type="button" class="button secondary" id="editor-cancel">Cancelar</button><button type="submit" class="button primary" id="editor-save">Guardar cambios</button></div></form></dialog>
<dialog id="confirmation" aria-labelledby="confirmation-title"><div class="modal-heading"><h2 id="confirmation-title">Eliminar registro</h2></div><p id="confirmation-text"></p><p class="muted">También se eliminarán sus relaciones. Esta acción no se puede deshacer.</p><p class="form-message error" id="confirmation-error" role="alert"></p><div class="modal-actions"><button class="button secondary" id="delete-cancel">Cancelar</button><button class="button danger" id="delete-confirm">Eliminar</button></div></dialog>
</body></html>
