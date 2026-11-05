using System;
using System.Configuration;
using System.Data;
using System.Web.Security;
using System.Web.UI;
namespace WebAppPoliMusicV3 {
    public partial class Login : Page {
        protected void Page_Load(object sender, EventArgs e) { if (!IsPostBack) lblMessage.Text = string.Empty; }
        protected void BtnLogin_Click(object sender, EventArgs e) {
            string login = txtLogin.Text.Trim();
            if (string.IsNullOrWhiteSpace(login) || string.IsNullOrEmpty(txtPassword.Text)) { lblMessage.Text = "Escribe tu usuario y contraseña."; return; }
            try {
                var service = new BLL.PoliMusicV3.User(ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString);
                DataTable data = service.AuthenticateUser(login, EntityLayer.PoliMusicV3.Util.Hash.GeneratePasswordHash(txtPassword.Text));
                if (data.Rows.Count == 0) { lblMessage.Text = "Usuario o contraseña incorrectos."; return; }
                DataRow row = data.Rows[0];
                int type = Convert.ToInt32(row["USER_TYPE"]);
                if (type != EntityLayer.PoliMusicV3.Util.Constants.ID_USER_NORMAL && type != EntityLayer.PoliMusicV3.Util.Constants.ID_USER_ADMIN) { lblMessage.Text = "Usuario no autorizado."; return; }
                Session[EntityLayer.PoliMusicV3.Util.Constants.USER] = new EntityLayer.PoliMusicV3.User(Convert.ToInt32(row["ID_USER"]), Convert.ToString(row["USERNAME"]), null, Convert.ToString(row["EMAIL"]), Convert.ToString(row["BIRTHDAY"]), type, Convert.ToString(row["USER_PHOTO"]));
                FormsAuthentication.RedirectFromLoginPage(login, false);
            } catch (System.Data.SqlClient.SqlException ex) { Trace.Warn("PoliMusic", "Error al autenticar", ex); lblMessage.Text = "No se pudo conectar con la base de datos. Inténtalo nuevamente."; }
        }
        protected void LinkButtonNewUser_Click(object sender, EventArgs e) { Response.Redirect("~/SignUp", true); }
    }
}