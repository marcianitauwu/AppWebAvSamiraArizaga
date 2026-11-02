<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="SignUP.aspx.cs" Inherits="WebAppPoliMusicV2.SignUP" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml" lang="es">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PoliMusic · Registro de usuario</title>
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
                        <h1 class="pm-auth-headline">Crea tu cuenta<br /><span>y empieza a escuchar.</span></h1>
                        <p class="pm-auth-lede">
                            Regístrate una sola vez y tendrás acceso a toda la biblioteca musical.
                            Tu foto de perfil es opcional: si no la subes, se asigna una por defecto.
                        </p>
                    </div>

                    <ul class="pm-auth-points">
                        <li>
                            <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                                <path d="M20 6 9 17l-5-5"></path>
                            </svg>
                            Registro gratuito en un solo paso
                        </li>
                        <li>
                            <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                                <rect x="4" y="10" width="16" height="10" rx="2"></rect>
                                <path d="M8 10V7a4 4 0 0 1 8 0v3"></path>
                            </svg>
                            Contraseña protegida con hash SHA-1
                        </li>
                        <li>
                            <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                                <circle cx="12" cy="12" r="9"></circle>
                                <path d="M12 7.5V12l3 2"></path>
                            </svg>
                            Historial de reproducciones por canción
                        </li>
                    </ul>
                </section>

                <!-- ================= FORMULARIO ================= -->
                <section class="pm-auth-card">
                    <h2 class="pm-auth-title">Registro de usuario</h2>
                    <p class="pm-auth-sub">Los campos marcados con * son obligatorios.</p>

                    <div class="pm-field">
                        <label for="txtUserName">Nombre de usuario *</label>
                        <asp:TextBox ID="txtUserName" runat="server" CssClass="pm-input" placeholder="nombre.apellido" />
                    </div>

                    <div class="pm-field">
                        <label for="txtEmail">Correo electrónico *</label>
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="pm-input" placeholder="usuario@epn.edu.ec" />
                    </div>

                    <div class="pm-grid-2">
                        <div class="pm-field">
                            <label for="txtPassword">Contraseña *</label>
                            <asp:TextBox ID="txtPassword" runat="server" TextMode="Password" CssClass="pm-input" placeholder="Mínimo 8 caracteres" />
                        </div>
                        <div class="pm-field">
                            <label for="txtConfirmPassword">Confirmar contraseña *</label>
                            <asp:TextBox ID="txtConfirmPassword" runat="server" TextMode="Password" CssClass="pm-input" placeholder="Repite la contraseña" />
                        </div>
                    </div>

                    <div class="pm-field">
                        <label for="txtBirthDate">Fecha de nacimiento</label>
                        <asp:TextBox ID="txtBirthDate" runat="server" CssClass="pm-input" placeholder="dd/mm/aaaa" />
                    </div>

                    <div class="pm-field">
                        <label for="fupPhoto">Foto de perfil</label>
                        <asp:FileUpload ID="fupPhoto" runat="server" CssClass="pm-input pm-file" />
                    </div>

                    <asp:Panel ID="frmConfirmation" runat="server" Visible="true">
                        <asp:Label ID="lblMessage" runat="server" CssClass="pm-auth-msg"></asp:Label>
                    </asp:Panel>

                    <asp:Button ID="btnSumbit" runat="server" Text="Registrarme" CssClass="pm-btn-primary" OnClick="btnSumbit_Click" />

                    <div class="pm-auth-links">
                        <span>¿Ya tienes una cuenta?</span>
                        <asp:HyperLink ID="HyperLink1" NavigateUrl="~/Login.aspx" runat="server">Volver al inicio de sesión</asp:HyperLink>
                    </div>
                </section>

            </div>
        </div>
    </form>
</body>
</html>
