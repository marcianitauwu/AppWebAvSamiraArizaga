using System;
using System.Runtime.InteropServices;
using System.Security.Cryptography;

[assembly: ComVisible(false)]
[assembly: Guid("1A48551E-DA10-46E6-8D18-1FA9E5DC8E65")]
namespace PoliMusic {
    [ComVisible(true)]
    [Guid("329E9CE3-ACBE-4692-B9B3-5942B03A0C65")]
    [InterfaceType(ComInterfaceType.InterfaceIsDual)]
    public interface ISecurity {
        string Pbkdf2(string password, string saltHex, int iterations);
    }
    [ComVisible(true)]
    [Guid("2E2D0A30-3C12-4ED5-A7BB-9A9812B0CF35")]
    [ProgId("PoliMusic.Security")]
    [ClassInterface(ClassInterfaceType.None)]
    public sealed class Security : ISecurity {
        public string Pbkdf2(string password, string saltHex, int iterations) {
            if (password == null || password.Length > 128 || saltHex == null || saltHex.Length != 32 || iterations < 10000 || iterations > 2000000)
                throw new ArgumentException("Invalid password derivation parameters.");
            byte[] salt = new byte[saltHex.Length / 2];
            for (int i = 0; i < salt.Length; i++) salt[i] = Convert.ToByte(saltHex.Substring(i * 2, 2), 16);
            using (var derive = new Rfc2898DeriveBytes(password, salt, iterations, HashAlgorithmName.SHA256))
                return BitConverter.ToString(derive.GetBytes(32)).Replace("-", "").ToLowerInvariant();
        }
    }
}
