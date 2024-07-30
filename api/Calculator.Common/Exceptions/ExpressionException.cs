using System;

namespace Calculator.Common.Exceptions
{
    public class ExpressionException : Exception
    {
        public ExpressionException() : base()
        {
        }

        public ExpressionException(string? message) : base(message)
        {
        }

        public ExpressionException(string? message, Exception? innerException) : base(message, innerException)
        {
        }
    }
}
