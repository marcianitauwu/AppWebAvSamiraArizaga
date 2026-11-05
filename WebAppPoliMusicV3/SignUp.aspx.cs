using System;
using System.Configuration;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;
using System.Web.UI;
namespace WebAppPoliMusicV3 {
    public partial class SignUp : Page {
        protected void Page_Load(object sender, EventArgs e) { }
        protected void btnSumbit_Click(object sender, EventArgs e) {
            var user = new EntityLayer.PoliMusicV3.User { UserName = txtUserName.Text.Trim(), Email = txtEmail.Text.Trim(), Password = txtPassword.Text, UserType = EntityLayer.PoliMusicV3.Util.Constants.ID_USER_NORMAL };
            string error = UserFieldsRequiredValidations(user);
            if (error.Length > 0) { lblMessage.Text = error; return; }
            if (user.Password != txtConfirmPassword.Text) { lblMessage.Text = "Las contraseñas no coinciden."; return; }
            if (!string.IsNullOrWhiteSpace(txtBirthDate.Text)) {
                DateTime date;
                if (!DateTime.TryParseExact(txtBirthDate.Text.Trim(), "dd/MM/yyyy", CultureInfo.InvariantCulture, DateTimeStyles.None, out date) || date > DateTime.Today || date.Year < 1753) { lblMessage.Text = "La fecha debe ser válida, no futura y tener formato dd/MM/yyyy."; return; }
                user.Birthday = date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            }
            try {
                var service = new BLL.PoliMusicV3.User(ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString);
                error = service.ValidationsDuplicated(user);
                if (error.Length > 0) { lblMessage.Text = error; return; }
                string folder = ConfigurationManager.AppSettings["userPhotoPath"];
                string imageName = Guid.NewGuid().ToString("N");
                if (fupPhoto.HasFile) {
                    error = new FileManagement().SaveImageOnServer(fupPhoto, folder, imageName);
                    user.Photo = folder + imageName + Path.GetExtension(fupPhoto.FileName).ToLowerInvariant();
                } else {
                    error = new FileManagement().SaveDefaultImageOnServer(folder, imageName);
                    user.Photo = folder + imageName + ".jpg";
                }
                if (error.Length > 0) { lblMessage.Text = error; return; }
                user.Password = EntityLayer.PoliMusicV3.Util.Hash.GeneratePasswordHash(user.Password);
                try {
                    if (service.Save(user) != 1) throw new InvalidOperationException("No se guardó el usuario.");
                } catch {
                    string image = Server.MapPath(user.Photo);
                    if (File.Exists(image)) File.Delete(image);
                    throw;
                }
                lblMessage.Text = "Usuario registrado correctamente. Ya puedes iniciar sesión.";
                txtPassword.Text = txtConfirmPassword.Text = string.Empty;
                btnSumbit.Enabled = false;
            } catch (Exception ex) { Trace.Warn("PoliMusic", "Error de registro", ex); lblMessage.Text = "No se pudo registrar el usuario. Inténtalo nuevamente."; }
        }
        public string UserFieldsRequiredValidations(EntityLayer.PoliMusicV3.User user) {
            if (string.IsNullOrWhiteSpace(user.UserName)) return "El usuario es obligatorio.";
            if (user.UserName.Length > 50 || !Regex.IsMatch(user.UserName, @"^[\p{L}\p{N}_.-]+$")) return "Usa hasta 50 letras, números, puntos, guiones o guiones bajos para el usuario.";
            if (string.IsNullOrWhiteSpace(user.Email) || user.Email.Length > 50 || !IsValidEmail(user.Email)) return "Escribe un correo válido de hasta 50 caracteres.";
            if (string.IsNullOrEmpty(user.Password)) return "La contraseña es obligatoria.";
            return string.Empty;
        }
        public static bool IsValidEmail(string email) { return !string.IsNullOrWhiteSpace(email) && Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$", RegexOptions.IgnoreCase); }
    }
}