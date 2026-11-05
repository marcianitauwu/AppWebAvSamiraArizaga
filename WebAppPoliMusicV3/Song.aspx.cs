using System;
using System.Configuration;
using System.Data;
using System.IO;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : Page
    {
        private BLL.PoliMusicV3.Song Service { get { return new BLL.PoliMusicV3.Song(ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString); } }
        protected void Page_Load(object sender, EventArgs e) { }
        protected void Page_PreRender(object sender, EventArgs e)
        {
            try
            {
                DataTable songs = Service.Search(txtSearch.Text);
                if (gvSongs.PageIndex * gvSongs.PageSize >= songs.Rows.Count) gvSongs.PageIndex = 0;
                gvSongs.DataSource = songs;
                gvSongs.DataBind();
                if (gvSongs.HeaderRow != null) gvSongs.HeaderRow.TableSection = TableRowSection.TableHeader;
                lblCount.Text = songs.Rows.Count + " canciones en tu colección";
            }
            catch (Exception ex) { Trace.Warn("PoliMusic", "Error al cargar canciones", ex); lblMessage.Text = "No se pudo cargar el catálogo. Inténtalo de nuevo."; }
        }
        protected void Search_Click(object sender, EventArgs e) { gvSongs.PageIndex = 0; }
        protected void Clear_Click(object sender, EventArgs e) { txtSearch.Text = string.Empty; gvSongs.PageIndex = 0; }
        protected void Page_Changing(object sender, GridViewPageEventArgs e) { gvSongs.PageIndex = e.NewPageIndex; }
        // Las rutas de audio se restringen a archivos MP3 dentro de SongFiles.
        private string AudioUrl(string storedPath)
        {
            if (string.IsNullOrWhiteSpace(storedPath)) return null;
            string path = storedPath.Replace('\\', '/');
            if (!path.StartsWith("~/SongFiles/", StringComparison.OrdinalIgnoreCase) && !path.StartsWith("SongFiles/", StringComparison.OrdinalIgnoreCase)) return null;
            string name = Path.GetFileName(path);
            if (!string.Equals(Path.GetExtension(name), ".mp3", StringComparison.OrdinalIgnoreCase)) return null;
            string appPath = "~/SongFiles/" + name;
            return File.Exists(Server.MapPath(appPath)) ? ResolveUrl(appPath) : null;
        }
        protected void Song_Bound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow) return;
            var row = (DataRowView)e.Row.DataItem;
            bool exists = AudioUrl(Convert.ToString(row["SONG_PATH"])) != null;
            var play = (LinkButton)e.Row.FindControl("btnPlay");
            play.Visible = exists;
            play.ToolTip = "Reproducir " + Convert.ToString(row["SONG_NAME"]);
            e.Row.FindControl("lblMissing").Visible = !exists;
        }
        protected void Song_Command(object sender, GridViewCommandEventArgs e)
        {
            if (e.CommandName != "Listen") return;
            int id;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), out id) || id <= 0) return;
            try
            {
                var song = Service.ReadById(id);
                string url = song == null ? null : AudioUrl(song.Path);
                if (url == null) { lblMessage.Text = "El archivo de esta canción no está disponible."; return; }
                Service.RegisterPlay(id);
                litNowPlaying.Text = song.Name + " · " + song.Artist;
                musicPlayer.Attributes["src"] = url;
                musicPlayer.Attributes["autoplay"] = "autoplay";
            }
            catch (Exception ex) { Trace.Warn("PoliMusic", "Error al reproducir", ex); lblMessage.Text = "No se pudo reproducir la canción. Inténtalo de nuevo."; }
        }
    }
}
