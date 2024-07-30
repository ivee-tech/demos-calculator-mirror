using System;

namespace Calculator.Common.Models
{
    public class OperationLogRequest
    {
        public string Expression { get; set; }
        public double Result { get; set; }
        public string Error { get; set; }
    }
}
