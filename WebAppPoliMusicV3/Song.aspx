<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>
<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <link href="Content/library.css" rel="stylesheet" />
    <main class="music-library">
        <header class="library-heading"><div><p class="eyebrow">TU BIBLIOTECA MUSICAL</p><h1>Canciones para tu día</h1><p>Explora tu música y encuentra tu próximo favorito.</p></div><span class="library-mark" aria-hidden="true">♫</span></header>
        <section class="library-panel" aria-label="Catálogo de canciones">
            <asp:Panel ID="pnlSearch" runat="server" DefaultButton="btnSearch" CssClass="library-tools">
                <div><h2>Tu colección</h2><asp:Label ID="lblCount" runat="server" /></div>
                <div class="search-controls"><asp:Label runat="server" AssociatedControlID="txtSearch" Text="Buscar música" CssClass="visually-hidden" /><asp:TextBox ID="txtSearch" runat="server" MaxLength="60" placeholder="Canción, artista o álbum" /><asp:Button ID="btnSearch" runat="server" Text="Buscar" OnClick="Search_Click" /><asp:Button ID="btnClear" runat="server" Text="Limpiar" OnClick="Clear_Click" /></div>
            </asp:Panel>
            <asp:Label ID="lblMessage" runat="server" CssClass="library-message" role="status" />
            <div class="table-responsive">
                <asp:GridView ID="gvSongs" runat="server" AutoGenerateColumns="false" DataKeyNames="ID_SONG" AllowPaging="true" PageSize="8" CssClass="song-table" GridLines="None" OnPageIndexChanging="Page_Changing" OnRowCommand="Song_Command" OnRowDataBound="Song_Bound" EmptyDataText="No se encontraron canciones. Prueba otra búsqueda." UseAccessibleHeader="true">
                    <Columns>
                        <asp:BoundField DataField="ID_SONG" HeaderText="#" />
                        <asp:BoundField DataField="SONG_NAME" HeaderText="Canción" />
                        <asp:BoundField DataField="ARTIST_NAME" HeaderText="Artista" NullDisplayText="Sin artista" />
                        <asp:BoundField DataField="ALBUM_TITLE" HeaderText="Álbum" NullDisplayText="Sin álbum" />
                        <asp:BoundField DataField="PLAYS" HeaderText="Reproducciones" />
                        <asp:TemplateField HeaderText="Escuchar"><ItemTemplate><asp:LinkButton ID="btnPlay" runat="server" CommandName="Listen" CommandArgument='<%# Eval("ID_SONG") %>' CssClass="play-button" Text="▶ Reproducir" CausesValidation="false" /><asp:Label ID="lblMissing" runat="server" Text="Archivo no disponible" Visible="false" CssClass="missing-file" /></ItemTemplate></asp:TemplateField>
                    </Columns>
                    <PagerStyle CssClass="song-pager" />
                </asp:GridView>
            </div>
        </section>
        <section class="music-player" aria-label="Reproductor"><div><span class="eyebrow">SONANDO AHORA</span><h2><asp:Literal ID="litNowPlaying" runat="server" Mode="Encode" Text="Selecciona una canción" /></h2><p id="playerStatus" role="status">Usa Reproducir en tu colección para escuchar.</p></div><audio id="musicPlayer" runat="server" controls="controls" preload="none"></audio></section>
    </main>
    <script src="Scripts/library.js"></script>
</asp:Content>
