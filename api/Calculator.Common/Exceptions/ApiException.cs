using System;

namespace Calculator.Common.Exceptions
{
    public class ApiException : Exception
    {
        public string Url { get; private set; }
        public int Code { get; private set; }
        public string Status { get; private set; }
        public string Type { get; private set; }

        public ApiException(string url, int code, string status, string type, string message, Exception exception)
            : base(message, exception)
        {
            Url = url;
            Code = code;
            Status = status;
            Type = type;
        }
    }
}
