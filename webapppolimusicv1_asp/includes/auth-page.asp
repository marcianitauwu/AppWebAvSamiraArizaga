<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="theme-color" content="#171021"><title><%=isRegister?'Crear cuenta':'Iniciar sesión'%> · PoliMusic</title>
  <link rel="icon" href="assets/logo.svg?v=2" type="image/svg+xml"><link rel="stylesheet" href="assets/style.css?v=2">
  <script src="assets/auth.js" defer></script>
</head>
<body class="auth-page" data-mode="<%=isRegister?'register':'login'%>">
  <main class="auth-layout">
    <section class="auth-story" aria-label="PoliMusic">
      <a class="brand" href="login.asp"><img src="assets/logo.svg?v=2" alt="" width="40" height="40">Poli<span>Music</span></a>
      <div class="story-copy"><div class="eyebrow">DALE PLAY A TU MUNDO</div><h1>Tu música.<br>Tu espacio.<br><span>Tu momento.</span></h1><p>Redescubre lo que te mueve. Tus canciones, artistas y álbumes favoritos, en un solo lugar.</p></div>
      <div class="auth-record" aria-hidden="true"><div class="record-grooves"><div class="record-label">p<span>m</span><small>POLIMUSIC · SIDE A</small></div></div><div class="record-caption">BUENOS MOMENTOS, EN REPEAT.</div></div>
      <p class="story-footer">Hecho para escuchar. Diseñado para sentir.</p>
    </section>
    <section class="auth-form-panel"><div class="auth-form-wrap">
      <span class="pill"><svg class="icon"><use href="assets/icons.svg#headphones"/></svg> TU PRÓXIMA FAVORITA TE ESPERA</span>
      <h2><%=isRegister?'Encuentra tu ritmo.':'Qué bueno verte.'%></h2><p class="muted"><%=isRegister?'Crea tu cuenta y empieza a explorar PoliMusic.':'Inicia sesión y deja que la música siga.'%></p>
      <form id="auth-form" method="post" action="api.asp?action=<%=isRegister?'register':'login'%>">
        <label for="username">Usuario</label><input id="username" name="username" required minlength="3" maxlength="50" autocomplete="username" placeholder="<%=isRegister?'Elige tu nombre de usuario':'Tu nombre de usuario'%>">
        <% if(isRegister){ %><label for="email">Correo electrónico</label><input id="email" name="email" type="email" required maxlength="50" autocomplete="email" placeholder="tu@correo.com"><% } %>
        <label for="password">Contraseña</label><div class="password-field"><input id="password" name="password" type="password" required <%=isRegister?'minlength="10"':''%> maxlength="128" autocomplete="<%=isRegister?'new-password':'current-password'%>" placeholder="<%=isRegister?'Al menos 10 caracteres':'Ingresa tu contraseña'%>"><button type="button" class="icon-button password-toggle" aria-label="Mostrar contraseña" aria-pressed="false"><svg class="icon"><use href="assets/icons.svg#eye"/></svg></button></div>
        <% if(isRegister){ %><label for="confirm">Confirmar contraseña</label><input id="confirm" name="confirm" type="password" required minlength="10" maxlength="128" autocomplete="new-password" placeholder="Escribe de nuevo tu contraseña"><% } %>
        <div id="auth-message" class="form-message" role="status" aria-live="polite"></div>
        <button id="auth-submit" type="submit" class="button primary wide"><%=isRegister?'Crear mi cuenta':'Entrar a PoliMusic'%><svg class="icon"><use href="assets/icons.svg#arrow-right"/></svg></button>
      </form>
      <p class="auth-switch"><%=isRegister?'¿Ya tienes una cuenta?':'¿Primera vez por aquí?'%> <a href="<%=isRegister?'login.asp':'register.asp'%>"><%=isRegister?'Inicia sesión':'Crea una cuenta'%></a></p>
      <div class="auth-note"><svg class="icon"><use href="assets/icons.svg#shield"/></svg>Tu espacio personal para disfrutar la música.</div>
    </div><footer>POLIMUSIC <span>·</span> SIENTE CADA NOTA</footer></section>
  </main>
</body></html>
