namespace Calculator.Web.Api.Models
{
    public class OperationLog
    {
        public int Id { get; set; }
        public string Expression { get; set; }
        public double Result { get; set; }
        public DateTime Date { get; set; }
        public string Error { get; set; }
    }
}
