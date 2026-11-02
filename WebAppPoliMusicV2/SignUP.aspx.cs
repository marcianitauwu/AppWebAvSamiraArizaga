using System;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    // El nombre de la clase debe coincidir con Inherits="WebAppPoliMusicV2.SignUP"
    // del marcado y con la declaración de SignUP.aspx.designer.cs.
    public partial class SignUP : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        protected void btnSumbit_Click(object sender, EventArgs e)
        {
            string messageValidations = string.Empty;

            // Cada envio empieza con el mensaje limpio y en color de error.
            lblMessage.Text = string.Empty;
            lblMessage.CssClass = "pm-auth-msg";

            string userName = txtUserName.Text.Trim();
            string password = txtPassword.Text;
            string email = txtEmail.Text.Trim();
            string birthday = string.Empty;
            if (txtBirthDate.Text.Trim() != string.Empty)
            {
                DateTime d;
                // Se aceptan "dd/MM/yyyy" y "d/M/yyyy" (por ejemplo 05/03/2003 y 5/3/2003).
                string[] formats = new string[] { "dd/MM/yyyy", "d/M/yyyy" };
                if (DateTime.TryParseExact(txtBirthDate.Text.Trim(), formats, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out d))
                {
                    birthday = d.ToString("yyyy-MM-dd");
                }
                else
                {
                    lblMessage.Text = "La fecha de nacimiento debe tener el formato dd/MM/yyyy.";
                    return;
                }
            }
            string photoName = fupPhoto.FileName;
            int type = Util.Constants.ID_USER_NORMAL;

            string newImageName = userName.Replace(" ", string.Empty);

            string strImageFolder = ConfigurationManager.AppSettings["userPhotoPath"];
            string strFileNameExtension = System.IO.Path.GetExtension(fupPhoto.FileName);
            string newFileNameWithExtension = strImageFolder + newImageName + strFileNameExtension;

            Entities.User user = new Entities.User();
            user.UserName = userName;
            user.Email = email;
            user.Password = password;
            user.Birthday = birthday;
            user.UserType = type;
            user.Photo = newFileNameWithExtension;

            string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
            messageValidations = UserFieldsRequiredValidations(user);
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }
            // El formulario pide confirmar la contrasena, por lo que ambas deben coincidir.
            if (password != txtConfirmPassword.Text)
            {
                lblMessage.Text = "Las contraseñas no coinciden.";
                return;
            }
            messageValidations = new BLL.User(strConnString).ValidationsDuplicated(user);
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }
            if (fupPhoto.HasFile)
            {
                messageValidations = new FileManagement().SaveImageOnServer(fupPhoto, strImageFolder, newImageName);
            }
            else
            {
                messageValidations = new FileManagement().SaveDefaultImageOnServer(strImageFolder, newImageName);
                user.Photo += ".jpg";
            }
            if (messageValidations != string.Empty)
            {
                lblMessage.Text = messageValidations;
                return;
            }
            user.Password = Util.Hash.GeneratePasswordHash(password);
            new BLL.User(strConnString).Save(user);
            lblMessage.CssClass = "pm-auth-msg is-ok";
            lblMessage.Text = "Usuario registrado correctamente. Ya puedes iniciar sesión.";
        }
        public string UserFieldsRequiredValidations(Entities.User user)
        {
            if (string.IsNullOrEmpty(user.UserName))
            {
                return "El nombre de usuario es obligatorio.";
            }
            if (string.IsNullOrEmpty(user.Email))
            {
                return "El correo electrónico es obligatorio.";
            }
            if (string.IsNullOrEmpty(user.Password))
            {
                return "La contraseña es obligatoria.";
            }
            if (!IsValidEmail(user.Email))
            {
                return "El correo electrónico no es válido.";
            }
            return string.Empty;
        }
        public static bool IsValidEmail(string email)
        {
            if (email == string.Empty || email.Replace(" ", "") == string.Empty)
                return false;

            try
            {
                // Normalize the domain
                email = Regex.Replace(email, @"(@)(.+)$", DomainMapper, RegexOptions.None);

                // Examines the domain part of the email and normalizes it.
                string DomainMapper(Match match)
                {
                    // Use IdnMapping class to convert Unicode domain names.
                    var idn = new IdnMapping();

                    // Pull out and process domain name (throws ArgumentException on invalid)
                    string domainName = idn.GetAscii(match.Groups[2].Value);

                    return match.Groups[1].Value + domainName;
                }
            }
            catch (Exception)
            {
                return false;
            }
            try
            {
                return Regex.IsMatch(email,
                    @"^[^@\s]+@[^@\s]+\.[^@\s]+$",
                    RegexOptions.IgnoreCase);
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}