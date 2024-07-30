using Microsoft.AspNetCore.Mvc;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
// using System.Data.SqlClient;
using Microsoft.Data.SqlClient;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis.CSharp.Scripting;
using Calculator.Web.Api.Models;
using Calculator.Web.Api.Configuration;
using Calculator.Web.Api.Services;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace Calculator.Web.Api.Controllers
{
    public class OperationService : IOperationService
    {

        private readonly bool _isProduction;
        private readonly IConfiguration _configuration;

        public OperationService(bool isProduction, IConfiguration configuration)
        {
            _isProduction = isProduction;
            _configuration = configuration;
        }

        public async Task<List<OperationLog>> Get(DateTime sd, DateTime ed)
        {
            var list = new List<OperationLog>();
            var connectionString = GetConnectionString();
            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    cmd.CommandText = "SELECT * FROM dbo.OperationLogs WHERE Date BETWEEN @sd AND @ed";
                    cmd.Parameters.AddWithValue("@sd", sd);
                    cmd.Parameters.AddWithValue("@ed", ed);
                    var rdr = await cmd.ExecuteReaderAsync();
                    while(rdr.Read())
                    {
                        int id = 0;
                        string expression = "";
                        double result = 0;
                        DateTime date = DateTime.MinValue;
                        string error = "";
                        rdr.TryGetValue<int>("Id", ref id);
                        rdr.TryGetValue<string>("Expression", ref expression);
                        rdr.TryGetValue<double>("Result", ref result);
                        rdr.TryGetValue<DateTime>("Date", ref date);
                        rdr.TryGetValue<string>("Error", ref error);
                        var log = new OperationLog()
                        {
                            Id = id,
                            Expression = expression,
                            Result = result,
                            Date = date,
                            Error = error
                        };
                        list.Add(log);
                    }
                }
            }
            return list;
        }

        public async Task<OperationResponse> ExecuteAndLogOperation(OperationRequest request)
        {
            if(string.IsNullOrEmpty(request?.Expression))
            {
                throw new Exception("Expression cannot be empty.");
            }
            var expression = Uri.UnescapeDataString(request?.Expression);
            var success = true;
            var error = string.Empty;
            double result = 0;
            try
            {
                result = await Execute(expression);
            }
            catch (Exception ex)
            {
                success = false;
                error = ex.ToString();
            }
            await LogOperation(expression, result, error);
            if (success)
            {
                return new OperationResponse { Expression = expression, Result = result };
            }
            else
            {
                throw new Exception(error);
            }
        }

        private string GetConnectionString()
        {
            if(_isProduction)
            {
                var cred = new DefaultAzureCredential();
                var kvUrl = $"https://{_configuration["Settings:KeyVaultName"]}.vault.azure.net";
                var kvUri = new Uri(kvUrl);
                var client = new SecretClient(kvUri, cred);
                var connectionString = client.GetSecret("ConnectionStrings--Default").Value.Value;
                return connectionString;
            }
            else
            {
                var connectionString = _configuration["ConnectionStrings:Default"];
                return connectionString;
            }
        }

        public async Task<double> Execute(string expression)
        {
            double result = 0;
            var pattern = @"(?<n>(\d)+(\.\d+)*)";
            var expr = Regex.Replace(expression, pattern, "(double)(${n})");
            result = await CSharpScript.EvaluateAsync<double>(expr).ConfigureAwait(false);
            return result;
        }

        private async Task LogOperation(string expression, double result, string error)
        {
            var connectionString = GetConnectionString();
            using (var conn = new SqlConnection(connectionString))
            {
                conn.Open();
                using (var cmd = conn.CreateCommand())
                {
                    var date = DateTime.Now;
                    cmd.CommandText = "INSERT INTO dbo.OperationLogs(Expression, Result, Date, Error) VALUES(@Expression, @Result, @Date, @Error)";
                    cmd.Parameters.AddWithValue("@Expression", expression);
                    cmd.Parameters.AddWithValue("@Result", result);
                    cmd.Parameters.AddWithValue("@Date", date);
                    cmd.Parameters.AddWithValue("@Error", error);
                    await cmd.ExecuteNonQueryAsync();
                }
            }
        }

    }
}
