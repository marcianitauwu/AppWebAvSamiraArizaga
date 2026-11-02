using System;
using System.Collections.Generic;
using System.IO;
using System.Web;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public class FileManagement : System.Web.UI.Page
    {
        /// <summary>
        /// Save a image on the server
        /// </summary>
        /// <param name="fileUpload">Object that contain the image</param>
        /// <param name="strFolder">Root folder</param>
        /// <param name="newFileName">Optional, if you want to use a custom name</param>
        /// <returns>Return an empty string if is OK or a error message</returns>
        public string SaveImageOnServer(FileUpload fileUpload, string strFolder, string newFileName)
        {
            try
            {
                string dataRequired = string.Empty;
                if (!fileUpload.HasFile)
                {
                    return "La imagen es obligatoria.";
                }
                if (!(fileUpload.PostedFile.ContentType == "image/jpeg" ||
                    fileUpload.PostedFile.ContentType == "image/jpg" ||
                    fileUpload.PostedFile.ContentType == "image/png")
                    )
                {
                    return "Solo se aceptan archivos JPEG o PNG.";
                }
                string fileExt = Path.GetExtension(fileUpload.FileName).ToLower();
                if (!(fileExt == ".jpg" || fileExt == ".jpeg" || fileExt == ".png"))
                {
                    return "Solo se aceptan archivos JPEG o PNG.";
                }
                if (fileUpload.PostedFile.ContentLength > 10485760) //10MB=10485760Bytes
                {
                    return "El archivo debe pesar menos de 10 MB.";
                }
                string strServerFolder = Server.MapPath(strFolder);
                string strFileName;
                if (newFileName != string.Empty)
                {
                    strFileName = newFileName;
                }
                else
                {
                    strFileName = Path.GetFileNameWithoutExtension(fileUpload.FileName);
                }
                string strFileNameExtension = Path.GetExtension(fileUpload.FileName).ToLower();
                string newServerFileNameWithExtension = strServerFolder + strFileName + strFileNameExtension;

                // Create the directory if it does not exist.
                if (!Directory.Exists(strServerFolder))
                {
                    Directory.CreateDirectory(strServerFolder);
                }
                fileUpload.SaveAs(newServerFileNameWithExtension);
                return string.Empty;
            }
            catch (Exception ex)
            {
                return "No se pudo subir el archivo: " + ex.Message;
            }
        }
        public string SaveDefaultImageOnServer(string strFolder, string newFileName)
        {
            try
            {
                string strServerFolder = Server.MapPath(strFolder);
                string strFileName = "default.jpg";
                string serverFileNameWithExtension = strServerFolder + strFileName;
                string servernewFileNameWithExtension = strServerFolder + newFileName + ".jpg";
                // Create the directory if it does not exist.
                if (Directory.Exists(strServerFolder))
                {
                    File.Copy(serverFileNameWithExtension, servernewFileNameWithExtension, true);
                }
                return string.Empty;
            }
            catch (Exception ex)
            {
                return "No se pudo subir el archivo: " + ex.Message;
            }
        }
        public string SaveSongOnServer(FileUpload fileUpload, string strFolder, string newFileName)
        {
            try
            {
                string dataRequired = string.Empty;
                if (!fileUpload.HasFile)
                {
                    return "Primero selecciona un archivo de canción.";
                }
                if (!(fileUpload.PostedFile.ContentType == "audio/mpeg" ||
                    fileUpload.PostedFile.ContentType == "audio/mpeg3" ||
                    fileUpload.PostedFile.ContentType == "audio/mp3")
                    )
                {
                    return "El archivo debe estar en formato MP3.";
                }
                string strFileNameExtension = Path.GetExtension(fileUpload.FileName).ToLower();
                if (strFileNameExtension != ".mp3")
                {
                    return "Solo se permite subir archivos con extensión .mp3.";
                }
                string strmaxFileSize = System.Configuration.ConfigurationManager.AppSettings["maxSongLength"];
                int maxFileSize = string.IsNullOrEmpty(strmaxFileSize) ? 1024 : Convert.ToInt32(strmaxFileSize);//10485760
                if (fileUpload.PostedFile.ContentLength > maxFileSize)
                {
                    return "El archivo MP3 es demasiado grande. El tamaño máximo permitido es " + maxFileSize / 1024 + " KB.";
                }
                string strFileName;
                if (newFileName != string.Empty)
                {
                    strFileName = newFileName;
                }
                else
                {
                    strFileName = Path.GetFileNameWithoutExtension(fileUpload.FileName);
                }

                string strServerFolder = Server.MapPath(strFolder);
                string newServerFileNameWithExtension = strServerFolder + strFileName + strFileNameExtension;

                // Create the directory if it does not exist.
                if (!Directory.Exists(strServerFolder))
                {
                    Directory.CreateDirectory(strServerFolder);
                }
                fileUpload.SaveAs(newServerFileNameWithExtension);
                return string.Empty;
            }
            catch (Exception ex)
            {
                return "No se pudo subir el archivo: " + ex.Message;
            }
        }
    }

}