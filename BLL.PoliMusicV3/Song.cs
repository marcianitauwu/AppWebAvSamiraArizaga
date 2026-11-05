using System;
using System.Collections.Generic;
using System.Data;


namespace BLL.PoliMusicV3
{
    /// <summary>
    /// Business logic layer for songs. The web pages must use this class
    /// instead of executing SQL, keeping the same separation used by BLL.User.
    /// </summary>
    public class Song
    {
        private const int MAX_FILTER_LENGTH = 60;

        private string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        /// <summary>
        /// Returns every song of the library.a
        /// </summary>
        public DataTable Read()
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Read();
        }

        /// <summary>
        /// Returns the songs that match the search text. When the text is empty
        /// the whole library is returned, so the page always has a data source.
        /// </summary>
        public DataTable Search(string searchText)
        {
            string filter = NormalizeFilter(searchText);
            if (filter.Length == 0)
            {
                return Read();
            }
            return new DAL.PoliMusicV3.Song(strConnectionString).Read(BuildLikePattern(filter));
        }

        /// <summary>
        /// Returns a single song or null when the identifier does not exist.
        /// </summary>
        public EntityLayer.PoliMusicV3.Song ReadById(int idSong)
        {
            if (idSong <= 0)
            {
                return null;
            }

            DataTable dtSong = new DAL.PoliMusicV3.Song(strConnectionString).ReadById(idSong);
            if (dtSong == null || dtSong.Rows.Count == 0)
            {
                return null;
            }

            DataRow row = dtSong.Rows[0];
            EntityLayer.PoliMusicV3.Song song = new EntityLayer.PoliMusicV3.Song();
            song.ID = Convert.ToInt32(row["ID_SONG"]);
            song.Name = Convert.ToString(row["SONG_NAME"]);
            song.Path = Convert.ToString(row["SONG_PATH"]);
            song.Plays = Convert.ToInt32(row["PLAYS"]);
            song.Artist = Convert.ToString(row["ARTIST_NAME"]);
            song.Album = Convert.ToString(row["ALBUM_TITLE"]);
            return song;
        }

        /// <summary>
        /// Registers one reproduction of the song. Returns the number of rows
        /// affected (0 when the identifier is not valid).
        /// </summary>
        public int RegisterPlay(int idSong)
        {
            if (idSong <= 0)
            {
                return 0;
            }
            return new DAL.PoliMusicV3.Song(strConnectionString).IncrementPlays(idSong);
        }

        /// <summary>
        /// Removes surrounding white spaces and limits the length of the
        /// search text so it cannot exceed the size of the LIKE parameter.
        /// </summary>
        private static string NormalizeFilter(string searchText)
        {
            string filter = (searchText == null) ? string.Empty : searchText.Trim();
            if (filter.Length > MAX_FILTER_LENGTH)
            {
                filter = filter.Substring(0, MAX_FILTER_LENGTH);
            }
            return filter;
        }

        /// <summary>
        /// Builds a LIKE pattern escaping the wildcard characters typed by the
        /// user, so a search for "100%" looks for the literal text and does not
        /// behave as a wildcard. The result is always used as a SqlParameter.
        /// </summary>
        public static string BuildLikePattern(string filter)
        {
            if (filter == null)
            {
                return "%";
            }

            string escaped = filter.Replace("[", "[[]");
            escaped = escaped.Replace("%", "[%]");
            escaped = escaped.Replace("_", "[_]");
            return "%" + escaped + "%";
        }
    }
}
