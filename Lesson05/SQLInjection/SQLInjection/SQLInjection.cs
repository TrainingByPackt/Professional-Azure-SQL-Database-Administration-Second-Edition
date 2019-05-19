using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.Sql;
using System.Data.SqlClient;
using System.Configuration;

namespace SampleApplication
{
    public partial class SQLInjection : Form
    {
        public SQLInjection()
        {
            InitializeComponent();
        }

        private void btnSearch_Click(object sender, EventArgs e)
        {
            string _SupplierName = txtSupplierName.Text;
            string _SupplierID = txtSupplierID.Text;
            string _server = ConfigurationSettings.AppSettings["server"].ToString();
            string _user = ConfigurationSettings.AppSettings["user"].ToString();
            string _database = ConfigurationSettings.AppSettings["database"].ToString();
            string _password = ConfigurationSettings.AppSettings["password"].ToString();
            string _Constr = "Server=tcp:" + _server + ".database.windows.net;Database=" + _database +";User ID =" + _user + "@" + _server +";Password=" + _password +";Trusted_Connection=False;Encrypt=True;";
            SqlConnection _con = new SqlConnection(_Constr);
            
            string _query = "select * from users where username = '" + _SupplierName + "' and usersecret = '" + _SupplierID + "'";
           
            _con.Open();

            SqlDataAdapter _sqlda = new SqlDataAdapter(_query, _con);
            DataSet ds = new DataSet();
            _sqlda.Fill(ds);
            dgvSupplier.DataSource = ds.Tables[0];
           



        }
    }
}
