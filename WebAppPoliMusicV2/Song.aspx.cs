using System;
using System.Configuration;
using System.Data;
using System.Globalization;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    /// <summary>
    /// Musical library of PoliMusic. The page reads the songs through BLL.Song,
    /// shows them in a GridView and plays the MP3 file with an HTML5 audio
    /// element handled by Scripts/polimusic.js.
    /// </summary>
    public partial class Song : System.Web.UI.Page
    {
        private const string CONNECTION_STRING_NAME = "BDD_PoliMusicConnectionString";
        private const string DEFAULT_USER_IMAGE = "~/UserImages/default.jpg";

        private const string VS_CURRENT_ID = "PM_CURRENT_ID";
        private const string VS_CURRENT_URL = "PM_CURRENT_URL";
        private const string VS_CURRENT_NAME = "PM_CURRENT_NAME";
        private const string VS_CURRENT_ARTIST = "PM_CURRENT_ARTIST";

        private string strConnString;
        private string strPageError;

        // ==================== CICLO DE VIDA ====================

        protected void Page_Load(object sender, EventArgs e)
        {
            // La sesion se valida siempre: el ticket de Forms Authentication
            // puede seguir vivo aunque la sesion haya expirado.
            Entities.User user = Session[Util.Constants.USER] as Entities.User;
            if (user == null)
            {
                FormsAuthentication.SignOut();
                Response.Redirect("~/Login.aspx", true);
                return;
            }

            RenderUserChrome(user);
        }

        /// <summary>
        /// La biblioteca se enlaza en PreRender: de esa forma el GridView
        /// refleja el resultado de cualquier evento (busqueda, paginacion,
        /// reproduccion) con una sola consulta por peticion.
        /// </summary>
        protected void Page_PreRender(object sender, EventArgs e)
        {
            BindLibrary();
            ConfigurePlayer();
        }

        // ==================== DATOS ====================

        private void BindLibrary()
        {
            string filter = (txtSearch.Text == null) ? string.Empty : txtSearch.Text.Trim();

            try
            {
                BLL.Song bll = new BLL.Song(GetConnectionString());

                DataTable dtAll = bll.Read();
                DecorateForView(dtAll);
                UpdateStats(dtAll);

                DataTable dtView;
                if (filter.Length == 0)
                {
                    dtView = dtAll;
                }
                else
                {
                    dtView = bll.Search(filter);
                    DecorateForView(dtView);
                }

                gvSongs.DataSource = dtView;
                gvSongs.DataBind();

                bool hasRows = dtView.Rows.Count > 0;
                gvSongs.Visible = hasRows;
                pnlEmpty.Visible = !hasRows;
                lnkClear.Visible = filter.Length > 0;

                if (hasRows)
                {
                    litResultInfo.Text = BuildResultInfo(dtView.Rows.Count, dtAll.Rows.Count, filter);
                }
                else
                {
                    litResultInfo.Text = "Sin resultados";
                    if (filter.Length > 0)
                    {
                        litEmptyTitle.Text = "No hay coincidencias";
                        litEmptyText.Text = "No se encontraron canciones para «" + HttpUtility.HtmlEncode(filter) +
                            "». Intenta con otro nombre, artista o álbum.";
                    }
                    else
                    {
                        litEmptyTitle.Text = "La biblioteca está vacía";
                        litEmptyText.Text = "Todavía no hay canciones registradas en BDD_PoliMusic.";
                    }
                }
            }
            catch (Exception ex)
            {
                LogError("BindLibrary", ex);
                ShowError("No se pudo cargar la biblioteca musical. Revisa la conexión con BDD_PoliMusic e inténtalo nuevamente.");
                gvSongs.Visible = false;
                pnlEmpty.Visible = false;
                lnkClear.Visible = filter.Length > 0;
                litResultInfo.Text = "No disponible";
                UpdateStats(null);
            }

            pnlError.Visible = !string.IsNullOrEmpty(strPageError);
            litErrorText.Text = HttpUtility.HtmlEncode(strPageError == null ? string.Empty : strPageError);
        }

        /// <summary>
        /// Adds the columns used only by the view: the initials of the song,
        /// the availability of the MP3 file and the text/class of the status.
        /// The database schema is not modified.
        /// </summary>
        private void DecorateForView(DataTable dt)
        {
            if (dt == null)
            {
                return;
            }

            if (!dt.Columns.Contains("INITIALS"))
            {
                dt.Columns.Add("INITIALS", typeof(string));
            }
            if (!dt.Columns.Contains("IS_AVAILABLE"))
            {
                dt.Columns.Add("IS_AVAILABLE", typeof(bool));
            }
            if (!dt.Columns.Contains("STATUS_TEXT"))
            {
                dt.Columns.Add("STATUS_TEXT", typeof(string));
            }
            if (!dt.Columns.Contains("STATUS_CLASS"))
            {
                dt.Columns.Add("STATUS_CLASS", typeof(string));
            }
            if (!dt.Columns.Contains("ARTIST_DISPLAY"))
            {
                dt.Columns.Add("ARTIST_DISPLAY", typeof(string));
            }
            if (!dt.Columns.Contains("ALBUM_DISPLAY"))
            {
                dt.Columns.Add("ALBUM_DISPLAY", typeof(string));
            }

            foreach (DataRow row in dt.Rows)
            {
                row["INITIALS"] = BuildInitials(Convert.ToString(row["SONG_NAME"]));

                string url = ResolveMediaUrl(Convert.ToString(row["SONG_PATH"]));
                bool available = IsMediaAvailable(url);

                row["IS_AVAILABLE"] = available;
                row["STATUS_TEXT"] = available ? "Disponible" : "Sin archivo";
                row["STATUS_CLASS"] = available ? "is-on" : "is-off";

                // TBL_PLAYER y TBL_TRACKLIST pueden no tener filas para una
                // cancion; se muestra un texto legible en lugar de una celda vacia.
                string artist = Convert.ToString(row["ARTIST_NAME"]);
                string album = Convert.ToString(row["ALBUM_TITLE"]);
                row["ARTIST_DISPLAY"] = string.IsNullOrEmpty(artist) ? "Sin artista" : artist;
                row["ALBUM_DISPLAY"] = string.IsNullOrEmpty(album) ? "Sin álbum" : album;
            }
        }

        private void UpdateStats(DataTable dt)
        {
            int songs = 0;
            int plays = 0;
            int available = 0;

            if (dt != null)
            {
                songs = dt.Rows.Count;
                foreach (DataRow row in dt.Rows)
                {
                    plays += Convert.ToInt32(row["PLAYS"]);
                    if (Convert.ToBoolean(row["IS_AVAILABLE"]))
                    {
                        available++;
                    }
                }
            }

            litStatSongs.Text = songs.ToString("N0", CultureInfo.InvariantCulture);
            litStatPlays.Text = plays.ToString("N0", CultureInfo.InvariantCulture);
            litStatAvailable.Text = available.ToString("N0", CultureInfo.InvariantCulture);
        }

        private static string BuildResultInfo(int shown, int total, string filter)
        {
            string label = (shown == 1) ? "canción" : "canciones";
            if (filter.Length == 0)
            {
                return string.Format(CultureInfo.InvariantCulture, "{0} {1} en la biblioteca", shown, label);
            }
            return string.Format(CultureInfo.InvariantCulture, "{0} de {1} {2} para «{3}»",
                shown, total, label, HttpUtility.HtmlEncode(filter));
        }

        // ==================== EVENTOS DEL GRIDVIEW ====================

        protected void gvSongs_RowCommand(object sender, GridViewCommandEventArgs e)
        {
            if (!string.Equals(e.CommandName, "Play", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            int idSong;
            if (!int.TryParse(Convert.ToString(e.CommandArgument), NumberStyles.Integer,
                    CultureInfo.InvariantCulture, out idSong) || idSong <= 0)
            {
                return;
            }

            try
            {
                BLL.Song bll = new BLL.Song(GetConnectionString());
                Entities.Song song = bll.ReadById(idSong);

                if (song == null)
                {
                    ShowError("La canción seleccionada ya no existe en la biblioteca.");
                    return;
                }

                string url = ResolveMediaUrl(song.Path);
                if (!IsMediaAvailable(url))
                {
                    // El texto se codifica una sola vez al pintar pnlError.
                    ShowError("El archivo de audio de «" + song.Name +
                        "» no se encuentra en la carpeta SongFiles del servidor.");
                    return;
                }

                // Solo se contabiliza la reproduccion cuando el archivo existe.
                bll.RegisterPlay(idSong);

                ViewState[VS_CURRENT_ID] = song.ID;
                ViewState[VS_CURRENT_URL] = url;
                ViewState[VS_CURRENT_NAME] = song.Name;
                ViewState[VS_CURRENT_ARTIST] = string.IsNullOrEmpty(song.Artist)
                    ? "Artista no registrado"
                    : song.Artist;

                // El reproductor arranca desde el inicio con esta cancion.
                hfPlayerTime.Value = "0";
                hfPlayerPlaying.Value = "1";
            }
            catch (Exception ex)
            {
                LogError("gvSongs_RowCommand", ex);
                ShowError("No se pudo iniciar la reproducción. Inténtalo nuevamente.");
            }
        }

        protected void gvSongs_RowDataBound(object sender, GridViewRowEventArgs e)
        {
            if (e.Row.RowType != DataControlRowType.DataRow)
            {
                return;
            }

            DataRowView drv = e.Row.DataItem as DataRowView;
            if (drv == null)
            {
                return;
            }

            bool available = Convert.ToBoolean(drv["IS_AVAILABLE"]);
            int idSong = Convert.ToInt32(drv["ID_SONG"]);
            string songName = Convert.ToString(drv["SONG_NAME"]);

            LinkButton btnPlay = e.Row.FindControl("btnPlay") as LinkButton;
            Label lblNoFile = e.Row.FindControl("lblNoFile") as Label;

            if (btnPlay != null)
            {
                btnPlay.Visible = available;
                if (available)
                {
                    btnPlay.ToolTip = "Reproducir «" + songName + "»";
                    btnPlay.Attributes["aria-label"] = "Reproducir " + songName;
                }
            }
            if (lblNoFile != null)
            {
                lblNoFile.Visible = !available;
            }

            string cssClass = "pm-row";
            if (idSong == GetCurrentSongId())
            {
                cssClass += " pm-row-playing";
            }
            e.Row.CssClass = cssClass;
        }

        protected void gvSongs_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvSongs.PageIndex = e.NewPageIndex;
        }

        // ==================== BUSQUEDA ====================

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            gvSongs.PageIndex = 0;
        }

        protected void lnkClear_Click(object sender, EventArgs e)
        {
            txtSearch.Text = string.Empty;
            gvSongs.PageIndex = 0;
        }

        // ==================== REPRODUCTOR ====================

        private void ConfigurePlayer()
        {
            int idSong = GetCurrentSongId();
            string url = Convert.ToString(ViewState[VS_CURRENT_URL]);
            string title = Convert.ToString(ViewState[VS_CURRENT_NAME]);
            string artist = Convert.ToString(ViewState[VS_CURRENT_ARTIST]);

            if (idSong <= 0 || string.IsNullOrEmpty(url))
            {
                litPlayerArt.Text = "&#9834;";
                litPlayerTitle.Text = "Ninguna canción seleccionada";
                litPlayerArtist.Text = "Elige una canción de la biblioteca para comenzar";
                litPlayerConfig.Text = "<script type=\"text/javascript\">window.PM_PLAYER=" +
                    BuildPlayerJson(string.Empty, false, 0) + ";</script>";
                hfPlayerTime.Value = "0";
                hfPlayerPlaying.Value = "0";
                return;
            }

            litPlayerArt.Text = HttpUtility.HtmlEncode(BuildInitials(title));
            litPlayerTitle.Text = HttpUtility.HtmlEncode(title);
            litPlayerArtist.Text = HttpUtility.HtmlEncode(artist);

            bool autoplay = string.Equals(hfPlayerPlaying.Value, "1", StringComparison.Ordinal);

            double startTime;
            if (!double.TryParse(hfPlayerTime.Value, NumberStyles.Float, CultureInfo.InvariantCulture, out startTime))
            {
                startTime = 0;
            }
            if (startTime < 0 || double.IsNaN(startTime) || double.IsInfinity(startTime))
            {
                startTime = 0;
            }

            litPlayerConfig.Text = "<script type=\"text/javascript\">window.PM_PLAYER=" +
                BuildPlayerJson(url, autoplay, startTime) + ";</script>";
        }

        private string BuildPlayerJson(string appRelativeUrl, bool autoplay, double startTime)
        {
            string resolved = string.IsNullOrEmpty(appRelativeUrl) ? string.Empty : ResolveUrl(appRelativeUrl);

            StringBuilder sb = new StringBuilder();
            sb.Append("{");
            sb.Append("src:").Append(ToJsString(resolved)).Append(",");
            sb.Append("autoplay:").Append(autoplay ? "true" : "false").Append(",");
            sb.Append("startTime:").Append(startTime.ToString("0.###", CultureInfo.InvariantCulture));
            sb.Append("}");
            return sb.ToString();
        }

        /// <summary>
        /// Builds a JavaScript string literal escaping quotes, control
        /// characters and the sequence that could close the script tag.
        /// </summary>
        private static string ToJsString(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return "''";
            }

            StringBuilder sb = new StringBuilder("'");
            foreach (char c in value)
            {
                switch (c)
                {
                    case '\\': sb.Append("\\\\"); break;
                    case '\'': sb.Append("\\'"); break;
                    case '"': sb.Append("\\\""); break;
                    case '\r': break;
                    case '\n': sb.Append("\\n"); break;
                    case '<': sb.Append("\\u003c"); break;
                    case '>': sb.Append("\\u003e"); break;
                    case '&': sb.Append("\\u0026"); break;
                    default:
                        if (c < 32)
                        {
                            sb.Append("\\u").Append(((int)c).ToString("x4", CultureInfo.InvariantCulture));
                        }
                        else
                        {
                            sb.Append(c);
                        }
                        break;
                }
            }
            sb.Append("'");
            return sb.ToString();
        }

        private int GetCurrentSongId()
        {
            object value = ViewState[VS_CURRENT_ID];
            return (value == null) ? 0 : Convert.ToInt32(value);
        }

        // ==================== USUARIO ====================

        private void RenderUserChrome(Entities.User user)
        {
            string displayName = BuildDisplayName(user.UserName);
            string role = (user.UserType == Util.Constants.ID_USER_ADMIN) ? "Administrador" : "Oyente";

            litGreeting.Text = HttpUtility.HtmlEncode(BuildGreeting() + ", " + displayName);
            litUserName.Text = HttpUtility.HtmlEncode(displayName);
            litUserNameSide.Text = HttpUtility.HtmlEncode(displayName);
            litUserType.Text = HttpUtility.HtmlEncode(role);
            litUserTypeSide.Text = HttpUtility.HtmlEncode(role);

            string avatar = BuildAvatarHtml(user.Photo, displayName);
            litAvatar.Text = avatar;
            litAvatarSide.Text = avatar;
        }

        private string BuildAvatarHtml(string photoPath, string displayName)
        {
            string resolved = ResolveMediaUrl(string.IsNullOrEmpty(photoPath) ? DEFAULT_USER_IMAGE : photoPath);

            if (!string.IsNullOrEmpty(resolved) && IsMediaAvailable(resolved))
            {
                return "<img class=\"pm-avatar\" src=\"" +
                    HttpUtility.HtmlAttributeEncode(ResolveUrl(resolved)) + "\" alt=\"\" />";
            }

            return "<span class=\"pm-avatar pm-avatar-initials\" aria-hidden=\"true\">" +
                HttpUtility.HtmlEncode(BuildInitials(displayName)) + "</span>";
        }

        private static string BuildDisplayName(string userName)
        {
            if (string.IsNullOrEmpty(userName))
            {
                return "Usuario";
            }

            string name = userName.Trim();

            if (name.IndexOf('.') > 0)
            {
                name = name.Substring(0, name.IndexOf('.'));
            }
            else if (name.IndexOf('_') > 0)
            {
                name = name.Substring(0, name.IndexOf('_'));
            }
            else
            {
                return name;
            }

            return CultureInfo.InvariantCulture.TextInfo.ToTitleCase(name.ToLowerInvariant());
        }

        private static string BuildGreeting()
        {
            int hour = DateTime.Now.Hour;
            if (hour < 12)
            {
                return "Buenos días";
            }
            if (hour < 19)
            {
                return "Buenas tardes";
            }
            return "Buenas noches";
        }

        /// <summary>
        /// Builds a short label (one or two letters) used as cover placeholder.
        /// Returns "PM" when there is no usable text.
        /// </summary>
        private static string BuildInitials(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return "PM";
            }

            char[] separators = new char[] { ' ', '.', '_', '-', '/', ',' };
            string[] parts = value.Split(separators, StringSplitOptions.RemoveEmptyEntries);

            StringBuilder initials = new StringBuilder(2);

            if (parts.Length == 1)
            {
                // Una sola palabra: se usan sus dos primeras letras o digitos.
                string word = parts[0];
                for (int i = 0; i < word.Length && initials.Length < 2; i++)
                {
                    if (char.IsLetterOrDigit(word[i]))
                    {
                        initials.Append(char.ToUpperInvariant(word[i]));
                    }
                }
            }
            else
            {
                // Varias palabras: se usa la inicial de las dos primeras.
                for (int i = 0; i < parts.Length && initials.Length < 2; i++)
                {
                    string part = parts[i];
                    for (int j = 0; j < part.Length; j++)
                    {
                        if (char.IsLetterOrDigit(part[j]))
                        {
                            initials.Append(char.ToUpperInvariant(part[j]));
                            break;
                        }
                    }
                }
            }

            if (initials.Length == 0)
            {
                return "PM";
            }
            return initials.ToString();
        }

        // ==================== UTILIDADES ====================

        /// <summary>
        /// Normalizes the path stored in TBL_SONG.SONG_PATH into an
        /// application relative path (~/...).
        /// </summary>
        private static string ResolveMediaUrl(string storedPath)
        {
            if (string.IsNullOrEmpty(storedPath))
            {
                return string.Empty;
            }

            string path = storedPath.Trim().Replace('\\', '/');

            if (path.StartsWith("~"))
            {
                return path;
            }
            if (path.StartsWith("/"))
            {
                return "~" + path;
            }
            return "~/" + path;
        }

        private bool IsMediaAvailable(string appRelativePath)
        {
            if (string.IsNullOrEmpty(appRelativePath))
            {
                return false;
            }

            try
            {
                string physicalPath = Server.MapPath(appRelativePath);
                return !string.IsNullOrEmpty(physicalPath) && File.Exists(physicalPath);
            }
            catch (Exception)
            {
                return false;
            }
        }

        private string GetConnectionString()
        {
            if (strConnString == null)
            {
                ConnectionStringSettings settings = ConfigurationManager.ConnectionStrings[CONNECTION_STRING_NAME];
                if (settings == null || string.IsNullOrEmpty(settings.ConnectionString))
                {
                    throw new ConfigurationErrorsException(
                        "No se encontró la cadena de conexión '" + CONNECTION_STRING_NAME + "' en Web.config.");
                }
                strConnString = settings.ConnectionString;
            }
            return strConnString;
        }

        private void ShowError(string message)
        {
            strPageError = message;
        }

        /// <summary>
        /// Writes the technical detail to the trace log only; the user always
        /// sees a friendly message instead of the exception information.
        /// </summary>
        private void LogError(string method, Exception ex)
        {
            System.Diagnostics.Trace.WriteLine("[PoliMusic] " + method + ": " + ex.Message, "PoliMusic");
            System.Diagnostics.Trace.WriteLine(ex.StackTrace, "PoliMusic");
        }
    }
}
