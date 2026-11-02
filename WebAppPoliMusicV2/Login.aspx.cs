using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV2
{
    public partial class Login : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
#if DEBUG
                txtLogin.Text = "samira.arizaga";
                txtPassword.Text = "12345678";
                txtPassword.Attributes.Add("value", txtPassword.Text);
                txtPassword.TextMode = TextBoxMode.Password;
#endif
                lblMessage.Text = string.Empty;
            }
        }

        protected void BtnLogin_Click(object sender, EventArgs e)
        {
            string login = txtLogin.Text;
            string password = txtPassword.Text;

            if (string.IsNullOrEmpty(login) || string.IsNullOrEmpty(password))
            {
                lblMessage.Text = "Por favor, escribe un usuario y una contraseña.";
                return;
            }
            password = Util.Hash.GeneratePasswordHash(password);
            DataTable dtUser = new BLL.User(strConnString).AuthenticateUser(login, password);

            if (dtUser != null && dtUser.Rows.Count > 0)
            {
                Entities.User user = new Entities.User();
                user.ID = Convert.ToInt32(dtUser.Rows[0]["ID_USER"]);
                user.UserName = login;
                user.Photo = dtUser.Rows[0]["USER_PHOTO"].ToString();
                user.Email = dtUser.Rows[0]["EMAIL"].ToString();
                user.Birthday = dtUser.Rows[0]["BIRTHDAY"].ToString();
                user.UserType = Convert.ToInt32(dtUser.Rows[0]["USER_TYPE"]);
                if (user.UserType == Util.Constants.ID_USER_NORMAL ||
                    user.UserType == Util.Constants.ID_USER_ADMIN)
                {
                    Session[Util.Constants.USER] = user;
                    // Ambos perfiles entran a la biblioteca musical. Este laboratorio
                    // no incluye una pantalla de administracion, por lo que no se
                    // redirige a DesktopAdmin.aspx (esa pagina no existe y daba 404).
                    FormsAuthentication.RedirectFromLoginPage(login, true);
                }
                else
                {
                    lblMessage.Text = "Usuario o contraseña incorrectos, inténtalo de nuevo.";
                    return;
                }
            }
            else
            {
                lblMessage.Text = "Usuario o contraseña incorrectos, inténtalo de nuevo.";
                return;
            }
            //#endif
            lblMessage.Text = string.Empty;
        }

        protected void LinkButtonNewUser_Click(object sender, EventArgs e)
        {
            // El archivo del proyecto se llama SignUP.aspx.
            Response.Redirect("~/SignUP.aspx", true);
        }
    }

}