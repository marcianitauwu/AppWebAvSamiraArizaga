using System;
using System.Web.Security;
using System.Web.UI;
namespace WebAppPoliMusicV3 {
    public partial class SiteMaster : MasterPage {
        protected void Page_Load(object sender, EventArgs e) {
            if (Session[EntityLayer.PoliMusicV3.Util.Constants.USER] == null) {
                FormsAuthentication.SignOut();
                Response.Redirect("~/Login", true);
            }
        }
    }
}