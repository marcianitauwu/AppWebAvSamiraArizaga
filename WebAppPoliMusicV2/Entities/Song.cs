using System;
using System.Collections.Generic;
using System.Web;

namespace WebAppPoliMusicV2.Entities
{
    /// <summary>
    /// Represents a song of the PoliMusic library.
    /// The artist and album values come from TBL_PLAYER / TBL_TRACKLIST,
    /// so a song may have more than one artist and more than one album.
    /// </summary>
    public class Song
    {
        public Song()
        {
        }

        public Song(int id, string name, string path, int plays, string artist, string album)
        {
            ID = id;
            Name = name;
            Path = path;
            Plays = plays;
            Artist = artist;
            Album = album;
        }

        public int ID { get; set; }
        public string Name { get; set; }
        public string Path { get; set; }
        public int Plays { get; set; }
        public string Artist { get; set; }
        public string Album { get; set; }
    }
}
