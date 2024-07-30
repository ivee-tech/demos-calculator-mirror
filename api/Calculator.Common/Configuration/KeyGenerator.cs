using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Calculator.Common.Configuration
{
    public static class KeyGenerator
    {
        public static char[] Chars = "ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvxyz0123456789".ToCharArray();

        public static string GetKey(int size, char[] chars)
        {
            var result = new StringBuilder(size);
            for (var i = 0; i < size; i++)
            {
                var idx = RandomNumberGenerator.GetInt32(chars.Length);
                result.Append(chars[idx]);
            }
            return result.ToString();
        }

        public static string GetKey(int size)
        {
            var result = new StringBuilder(size);
            for (var i = 0; i < size; i++)
            {
                var idx = RandomNumberGenerator.GetInt32(Chars.Length);
                result.Append(Chars[idx]);
            }
            return result.ToString();
        }
    }
}
