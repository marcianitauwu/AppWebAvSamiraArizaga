using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Web;

namespace WebAppPoliMusicV2.DAL
{
    /// <summary>
    /// Data access layer for the songs stored in BDD_PoliMusic.
    /// Only the tables that already exist in the database are used:
    /// TBL_SONG, TBL_PLAYER, TBL_ARTIST, TBL_TRACKLIST and TBL_ALBUM.
    /// </summary>
    public class Song
    {
        private string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        /// <summary>
        /// Base projection. The artist and album names are aggregated with
        /// OUTER APPLY + FOR XML PATH because TBL_PLAYER and TBL_TRACKLIST are
        /// many-to-many tables. A plain JOIN would return duplicated songs
        /// (one row per artist/album combination).
        /// </summary>
        private const string BaseSelect =
            "SELECT s.[ID_SONG] AS [ID_SONG], " +
            "s.[SONG_NAME] AS [SONG_NAME], " +
            "s.[SONG_PATH] AS [SONG_PATH], " +
            "ISNULL(s.[PLAYS], 0) AS [PLAYS], " +
            "ISNULL(ar.[ARTISTS], '') AS [ARTIST_NAME], " +
            "ISNULL(al.[ALBUMS], '') AS [ALBUM_TITLE] " +
            "FROM [TBL_SONG] s " +
            "OUTER APPLY (" +
            "    SELECT STUFF((" +
            "        SELECT ', ' + a.[ARTIST_NAME] + ' ' + ISNULL(a.[ARTIST_LASTNAME], '') " +
            "        FROM [TBL_PLAYER] p " +
            "        INNER JOIN [TBL_ARTIST] a ON a.[ID_ARTIST] = p.[ID_ARTIST] " +
            "        WHERE p.[ID_SONG] = s.[ID_SONG] " +
            "        ORDER BY a.[ARTIST_NAME] " +
            "        FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 2, '') AS [ARTISTS]" +
            ") ar " +
            "OUTER APPLY (" +
            "    SELECT STUFF((" +
            "        SELECT ', ' + b.[TITLE_ALBUM] " +
            "        FROM [TBL_TRACKLIST] t " +
            "        INNER JOIN [TBL_ALBUM] b ON b.[ID_ALBUM] = t.[ID_ALBUM] " +
            "        WHERE t.[ID_SONG] = s.[ID_SONG] " +
            "        ORDER BY b.[TITLE_ALBUM] " +
            "        FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 2, '') AS [ALBUMS]" +
            ") al";

        /// <summary>
        /// Returns every song of the library ordered by name.
        /// </summary>
        public DataTable Read()
        {
            DataTable dtSong = new DataTable();
            using (SqlConnection con = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(BaseSelect + " ORDER BY s.[SONG_NAME]", con))
                {
                    using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                    {
                        sda.Fill(dtSong);
                        return dtSong;
                    }
                }
            }
        }

        /// <summary>
        /// Returns the songs that match the given LIKE pattern.
        /// The pattern is always sent as a parameter, never concatenated.
        /// </summary>
        public DataTable Read(string filterPattern)
        {
            DataTable dtSong = new DataTable();
            using (SqlConnection con = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand())
                {
                    cmd.CommandText =
                        "SELECT q.[ID_SONG], q.[SONG_NAME], q.[SONG_PATH], q.[PLAYS], " +
                        "q.[ARTIST_NAME], q.[ALBUM_TITLE] " +
                        "FROM (" + BaseSelect + ") q " +
                        "WHERE q.[SONG_NAME] LIKE @FILTER " +
                        "   OR q.[ARTIST_NAME] LIKE @FILTER " +
                        "   OR q.[ALBUM_TITLE] LIKE @FILTER " +
                        "ORDER BY q.[SONG_NAME]";
                    cmd.Parameters.Add("@FILTER", SqlDbType.VarChar, 120).Value = filterPattern;
                    cmd.Connection = con;
                    using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                    {
                        sda.Fill(dtSong);
                        return dtSong;
                    }
                }
            }
        }

        /// <summary>
        /// Returns a single song by its identifier, or null when it does not exist.
        /// </summary>
        public DataTable ReadById(int idSong)
        {
            DataTable dtSong = new DataTable();
            using (SqlConnection con = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand())
                {
                    cmd.CommandText =
                        "SELECT q.[ID_SONG], q.[SONG_NAME], q.[SONG_PATH], q.[PLAYS], " +
                        "q.[ARTIST_NAME], q.[ALBUM_TITLE] " +
                        "FROM (" + BaseSelect + ") q " +
                        "WHERE q.[ID_SONG] = @ID_SONG";
                    cmd.Parameters.Add("@ID_SONG", SqlDbType.Int).Value = idSong;
                    cmd.Connection = con;
                    using (SqlDataAdapter sda = new SqlDataAdapter(cmd))
                    {
                        sda.Fill(dtSong);
                        return dtSong;
                    }
                }
            }
        }

        /// <summary>
        /// Increases the PLAYS counter of a song by one unit.
        /// It is only called when a song is actually played.
        /// </summary>
        public int IncrementPlays(int idSong)
        {
            using (SqlConnection con = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand())
                {
                    cmd.CommandText =
                        "UPDATE [TBL_SONG] SET [PLAYS] = ISNULL([PLAYS], 0) + 1 " +
                        "WHERE [ID_SONG] = @ID_SONG";
                    cmd.Parameters.Add("@ID_SONG", SqlDbType.Int).Value = idSong;
                    cmd.Connection = con;
                    con.Open();
                    return cmd.ExecuteNonQuery();
                }
            }
        }
    }
}
