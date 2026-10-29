<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV2.Song" MaintainScrollPositionOnPostback="true" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="es">
<head runat="server">
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>PoliMusic · Biblioteca musical</title>
    <link rel="stylesheet" href="Content/polimusic.css" />
</head>
<body>
    <form id="formSong" runat="server">

        <!-- ================= BARRA LATERAL ================= -->
        <aside class="pm-sidebar">
            <a class="pm-brand" href="Default.aspx">
                <span class="pm-brand-mark" aria-hidden="true">
                    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M9 18V5l10-2v13"></path>
                        <circle cx="6" cy="18" r="3"></circle>
                        <circle cx="16" cy="16" r="3"></circle>
                    </svg>
                </span>
                <span class="pm-brand-text">Poli<span>Music</span></span>
            </a>

            <nav class="pm-nav" aria-label="Navegación principal">
                <span class="pm-nav-label">Menú</span>

                <a class="pm-nav-item" href="Default.aspx" title="Inicio">
                    <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                        <path d="M3 10.5 12 3l9 7.5"></path>
                        <path d="M5.5 9.5V21h13V9.5"></path>
                        <path d="M9.5 21v-6h5v6"></path>
                    </svg>
                    <span>Inicio</span>
                </a>

                <a class="pm-nav-item is-active" href="Song.aspx" aria-current="page" title="Biblioteca musical">
                    <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                        <path d="M4 19V7.5L13 5v11"></path>
                        <circle cx="6.5" cy="19" r="2.5"></circle>
                        <circle cx="15.5" cy="16" r="2.5"></circle>
                        <path d="M19 14V4"></path>
                    </svg>
                    <span>Biblioteca musical</span>
                </a>

                <a class="pm-nav-item" href="Song.aspx" title="Canciones">
                    <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                        <path d="M8 6h13"></path>
                        <path d="M8 12h13"></path>
                        <path d="M8 18h13"></path>
                        <path d="M3.5 6h.01"></path>
                        <path d="M3.5 12h.01"></path>
                        <path d="M3.5 18h.01"></path>
                    </svg>
                    <span>Canciones</span>
                </a>
            </nav>

            <div class="pm-side-spacer"></div>

            <div class="pm-side-card">
                <asp:Literal ID="litAvatarSide" runat="server" />
                <span class="pm-side-meta">
                    <span class="pm-side-name">
                        <asp:Literal ID="litUserNameSide" runat="server" /></span>
                    <span class="pm-side-type">
                        <asp:Literal ID="litUserTypeSide" runat="server" /></span>
                </span>
            </div>

            <a class="pm-nav-item pm-logout" href="Logout.aspx" title="Cerrar sesión">
                <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                    <path d="M15 4h3.5A1.5 1.5 0 0 1 20 5.5v13a1.5 1.5 0 0 1-1.5 1.5H15"></path>
                    <path d="M10 8l-4 4 4 4"></path>
                    <path d="M6 12h9"></path>
                </svg>
                <span>Cerrar sesión</span>
            </a>
        </aside>

        <!-- ================= CONTENIDO ================= -->
        <main class="pm-main">

            <header class="pm-topbar">
                <div class="pm-topbar-left">
                    <span class="pm-eyebrow">Biblioteca musical</span>
                    <h1 class="pm-greeting">
                        <asp:Literal ID="litGreeting" runat="server" /></h1>
                    <p class="pm-subtitle">Escucha, busca y reproduce las canciones almacenadas en PoliMusic.</p>
                </div>

                <div class="pm-topbar-right">
                    <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btnSearch" CssClass="pm-search">
                        <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                            <circle cx="11" cy="11" r="6.5"></circle>
                            <path d="m16 16 4.5 4.5"></path>
                        </svg>
                        <asp:TextBox ID="txtSearch" runat="server" CssClass="pm-search-input" placeholder="Buscar por canción, artista o álbum…" MaxLength="60" />
                        <asp:LinkButton ID="lnkClear" runat="server" CssClass="pm-search-clear" OnClick="lnkClear_Click" ToolTip="Limpiar búsqueda" Visible="false">×</asp:LinkButton>
                        <asp:Button ID="btnSearch" runat="server" CssClass="pm-search-btn" Text="Buscar" OnClick="btnSearch_Click" />
                    </asp:Panel>

                    <div class="pm-account">
                        <asp:Literal ID="litAvatar" runat="server" />
                        <span class="pm-account-meta">
                            <span class="pm-account-name">
                                <asp:Literal ID="litUserName" runat="server" /></span>
                            <span class="pm-account-type">
                                <asp:Literal ID="litUserType" runat="server" /></span>
                        </span>
                    </div>
                </div>
            </header>

            <section class="pm-stats" aria-label="Resumen de la biblioteca">
                <article class="pm-stat">
                    <span class="pm-stat-label">Canciones</span>
                    <span class="pm-stat-value">
                        <asp:Literal ID="litStatSongs" runat="server" /></span>
                    <span class="pm-stat-hint">registradas en la biblioteca</span>
                </article>
                <article class="pm-stat">
                    <span class="pm-stat-label">Reproducciones</span>
                    <span class="pm-stat-value">
                        <asp:Literal ID="litStatPlays" runat="server" /></span>
                    <span class="pm-stat-hint">acumuladas en TBL_SONG</span>
                </article>
                <article class="pm-stat">
                    <span class="pm-stat-label">Archivos disponibles</span>
                    <span class="pm-stat-value">
                        <asp:Literal ID="litStatAvailable" runat="server" /></span>
                    <span class="pm-stat-hint">listos para reproducir</span>
                </article>
            </section>

            <section class="pm-panel">
                <div class="pm-panel-head">
                    <h2 class="pm-panel-title">Canciones</h2>
                    <span class="pm-panel-info">
                        <asp:Literal ID="litResultInfo" runat="server" /></span>
                </div>

                <asp:Panel ID="pnlError" runat="server" Visible="false" CssClass="pm-alert" role="alert">
                    <svg class="pm-alert-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                        <circle cx="12" cy="12" r="9"></circle>
                        <path d="M12 7.5v5.5"></path>
                        <path d="M12 16.5h.01"></path>
                    </svg>
                    <asp:Literal ID="litErrorText" runat="server" />
                </asp:Panel>

                <div class="pm-table-wrap">
                <asp:GridView ID="gvSongs" runat="server"
                    AutoGenerateColumns="false"
                    DataKeyNames="ID_SONG"
                    CssClass="pm-table"
                    GridLines="None"
                    UseAccessibleHeader="true"
                    AllowPaging="true"
                    PageSize="8"
                    PagerSettings-Mode="NumericFirstLast"
                    PagerSettings-Position="Bottom"
                    PagerStyle-CssClass="pm-pager"
                    OnRowCommand="gvSongs_RowCommand"
                    OnRowDataBound="gvSongs_RowDataBound"
                    OnPageIndexChanging="gvSongs_PageIndexChanging">
                    <Columns>

                        <asp:TemplateField HeaderText="ID" HeaderStyle-CssClass="pm-col-id" ItemStyle-CssClass="pm-col-id">
                            <ItemTemplate>
                                <span class="pm-id"><%# Eval("ID_SONG") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Nombre" HeaderStyle-CssClass="pm-col-song" ItemStyle-CssClass="pm-col-song">
                            <ItemTemplate>
                                <div class="pm-track">
                                    <span class="pm-track-art" aria-hidden="true"><%# Server.HtmlEncode(Convert.ToString(Eval("INITIALS"))) %></span>
                                    <span class="pm-track-text">
                                        <span class="pm-track-name"><%# Server.HtmlEncode(Convert.ToString(Eval("SONG_NAME"))) %></span>
                                        <span class="pm-track-sub">
                                            <span class="pm-dot <%# Eval("STATUS_CLASS") %>"></span>
                                            <%# Eval("STATUS_TEXT") %></span>
                                    </span>
                                </div>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:BoundField DataField="ARTIST_DISPLAY" HeaderText="Artista" HeaderStyle-CssClass="pm-col-artist" ItemStyle-CssClass="pm-col-artist" />

                        <asp:BoundField DataField="ALBUM_DISPLAY" HeaderText="Álbum" HeaderStyle-CssClass="pm-col-album" ItemStyle-CssClass="pm-col-album" />

                        <asp:TemplateField HeaderText="Ruta" HeaderStyle-CssClass="pm-col-path" ItemStyle-CssClass="pm-col-path">
                            <ItemTemplate>
                                <span class="pm-path" title='<%# Server.HtmlEncode(Convert.ToString(Eval("SONG_PATH"))) %>'><%# Server.HtmlEncode(Convert.ToString(Eval("SONG_PATH"))) %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Reproducciones" HeaderStyle-CssClass="pm-col-plays" ItemStyle-CssClass="pm-col-plays">
                            <ItemTemplate>
                                <span class="pm-plays">
                                    <svg class="pm-ico" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                                        <path d="M8 5v14l11-7z"></path>
                                    </svg>
                                    <%# Eval("PLAYS", "{0:N0}") %></span>
                            </ItemTemplate>
                        </asp:TemplateField>

                        <asp:TemplateField HeaderText="Reproducir" HeaderStyle-CssClass="pm-col-play" ItemStyle-CssClass="pm-col-play">
                            <ItemTemplate>
                                <asp:LinkButton ID="btnPlay" runat="server" CommandName="Play" CommandArgument='<%# Eval("ID_SONG") %>'
                                    CssClass="pm-play" CausesValidation="false" ToolTip="Reproducir canción">
                                    <span class="pm-play-glyph" aria-hidden="true">
                                        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                            <path d="M8 5v14l11-7z"></path>
                                        </svg>
                                    </span>
                                    <span class="pm-eq" aria-hidden="true"><i></i><i></i><i></i></span>
                                    <span class="pm-sr">Reproducir</span>
                                </asp:LinkButton>

                                <asp:Label ID="lblNoFile" runat="server" CssClass="pm-play pm-play-off" Visible="false"
                                    ToolTip="El archivo de audio no se encuentra en el servidor">
                                    <span class="pm-play-glyph" aria-hidden="true">
                                        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                                            <path d="M6 6l12 12M18 6L6 18"></path>
                                        </svg>
                                    </span>
                                    <span class="pm-sr">Archivo no disponible</span>
                                </asp:Label>
                            </ItemTemplate>
                        </asp:TemplateField>

                    </Columns>
                </asp:GridView>
                </div>

                <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="pm-empty">
                    <span class="pm-empty-ico" aria-hidden="true">
                        <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                            <path d="M9 18V5l10-2v13"></path>
                            <circle cx="6" cy="18" r="3"></circle>
                            <circle cx="16" cy="16" r="3"></circle>
                        </svg>
                    </span>
                    <span class="pm-empty-title">
                        <asp:Literal ID="litEmptyTitle" runat="server" /></span>
                    <span class="pm-empty-text">
                        <asp:Literal ID="litEmptyText" runat="server" /></span>
                </asp:Panel>
            </section>
        </main>

        <!-- ================= REPRODUCTOR ================= -->
        <div class="pm-player" id="pmPlayer">
            <div class="pm-player-track">
                <span class="pm-player-art" aria-hidden="true">
                    <asp:Literal ID="litPlayerArt" runat="server" /></span>
                <span class="pm-player-meta">
                    <span class="pm-player-title">
                        <asp:Literal ID="litPlayerTitle" runat="server" /></span>
                    <span class="pm-player-artist">
                        <asp:Literal ID="litPlayerArtist" runat="server" /></span>
                </span>
            </div>

            <div class="pm-player-center">
                <div class="pm-player-controls">
                    <button type="button" class="pm-btn-play" id="pmToggle" aria-label="Reproducir">
                        <svg class="pm-ico-play" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                            <path d="M8 5v14l11-7z"></path>
                        </svg>
                        <svg class="pm-ico-pause" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                            <path d="M8 5h3v14H8z"></path>
                            <path d="M13 5h3v14h-3z"></path>
                        </svg>
                    </button>
                </div>

                <div class="pm-player-line">
                    <span class="pm-time" id="pmCurrent">0:00</span>
                    <div class="pm-progress" id="pmProgress" role="slider" tabindex="0"
                        aria-label="Progreso de la canción" aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
                        <div class="pm-progress-fill" id="pmProgressFill"></div>
                        <div class="pm-progress-knob" id="pmProgressKnob"></div>
                    </div>
                    <span class="pm-time" id="pmDuration">0:00</span>
                </div>
            </div>

            <div class="pm-player-right">
                <button type="button" class="pm-btn-icon" id="pmMute" aria-label="Silenciar">
                    <svg class="pm-ico-vol" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                        <path d="M11 5 6.5 9H3v6h3.5L11 19z"></path>
                        <path d="M15.5 9.5a3.5 3.5 0 0 1 0 5"></path>
                        <path d="M18 7a7 7 0 0 1 0 10"></path>
                    </svg>
                    <svg class="pm-ico-muted" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
                        <path d="M11 5 6.5 9H3v6h3.5L11 19z"></path>
                        <path d="m16 10 4 4"></path>
                        <path d="m20 10-4 4"></path>
                    </svg>
                </button>
                <div class="pm-volume" id="pmVolume" role="slider" tabindex="0"
                    aria-label="Volumen" aria-valuemin="0" aria-valuemax="100" aria-valuenow="80">
                    <div class="pm-volume-fill" id="pmVolumeFill"></div>
                </div>
            </div>

            <audio id="pmAudio" preload="metadata"></audio>

            <asp:HiddenField ID="hfPlayerTime" runat="server" />
            <asp:HiddenField ID="hfPlayerPlaying" runat="server" />
        </div>

        <asp:Literal ID="litPlayerConfig" runat="server" />
        <script src="Scripts/polimusic.js"></script>
    </form>
</body>
</html>
