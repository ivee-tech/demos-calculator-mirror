using System;

namespace Calculator.Common.Exceptions
{
    public class LoggingException : Exception
    {
        public LoggingException() : base()
        {
        }

        public LoggingException(string? message) : base(message)
        {
        }

        public LoggingException(string? message, Exception? innerException) : base(message, innerException)
        {
        }
    }
}
