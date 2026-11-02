<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Login.aspx.cs" Inherits="WebAppPoliMusicV2.Login" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml" lang="es">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PoliMusic · Iniciar sesión</title>
    <link rel="stylesheet" href="Content/polimusic.css" />
</head>
<body>
    <form id="formLogin" runat="server">
        <div class="pm-auth">
            <div class="pm-auth-shell">

                <!-- ================= PORTADA DE MARCA ================= -->
                <section class="pm-auth-hero">
                    <a class="pm-brand" href="Login.aspx">
                        <span class="pm-brand-mark" aria-hidden="true">
                            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                <path d="M9 18V5l10-2v13"></path>
                                <circle cx="6" cy="18" r="3"></circle>
                                <circle cx="16" cy="16" r="3"></circle>
                            </svg>
                        </span>
                        <span class="pm-brand-text">Poli<span>Music</span></span>
                    </a>

                    <div>
                        <h1 class="pm-auth-headline">Tu música,<br /><span>en un solo lugar.</span></h1>
                        <p class="pm-auth-lede">
                            Biblioteca musical de la Escuela Politécnica Nacional. Consulta el catálogo
                            de canciones y escúchalas directamente desde el navegador.
                        </p>
                    </div>

                    <ul class="pm-auth-points">
                        <li>
                            <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                                <circle cx="11" cy="11" r="6.5"></circle>
                                <path d="m16 16 4.5 4.5"></path>
                            </svg>
                            Búsqueda por canción, artista o álbum
                        </li>
                        <li>
                            <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                                <path d="M8 5v14l11-7z"></path>
                            </svg>
                            Reproductor integrado con progreso y volumen
                        </li>
                        <li>
                            <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                                <circle cx="12" cy="8" r="3.5"></circle>
                                <path d="M5 20c0-3.6 3.1-6 7-6s7 2.4 7 6"></path>
                            </svg>
                            Perfil de usuario con foto personalizada
                        </li>
                    </ul>
                </section>

                <!-- ================= FORMULARIO ================= -->
                <section class="pm-auth-card">
                    <h2 class="pm-auth-title">Iniciar sesión</h2>
                    <p class="pm-auth-sub">Ingresa con tu usuario y contraseña para continuar.</p>

                    <div class="pm-field">
                        <label for="txtLogin">Usuario</label>
                        <asp:TextBox ID="txtLogin" runat="server" CssClass="pm-input" placeholder="nombre.apellido" />
                    </div>

                    <div class="pm-field">
                        <label for="txtPassword">Contraseña</label>
                        <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="pm-input" placeholder="Tu contraseña" />
                    </div>

                    <asp:Button ID="btnLogin" runat="server" Text="Ingresar" CssClass="pm-btn-primary" OnClick="BtnLogin_Click" />

                    <div class="pm-auth-links">
                        <span>¿Aún no tienes cuenta?</span>
                        <asp:LinkButton ID="LinkButtonNewUser" runat="server" OnClick="LinkButtonNewUser_Click">Registrarme</asp:LinkButton>
                    </div>

                    <asp:Label ID="lblMessage" runat="server" CssClass="pm-auth-msg"></asp:Label>
                </section>

            </div>
        </div>
    </form>
</body>
</html>
