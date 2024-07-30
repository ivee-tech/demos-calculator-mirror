using Microsoft.AspNetCore.Mvc;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
// using System.Data.SqlClient;
using Microsoft.Data.SqlClient;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis.CSharp.Scripting;
using Calculator.Common.Models;
using Calculator.Common.Configuration;
using Calculator.Common.Interfaces;
using Calculator.Common.Exceptions;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace Calculator.Web.Api.Controllers
{
    public class DirectOperationService : IOperationService
    {

        private readonly bool _isProduction;

        private readonly IWebHostEnvironment _environment;
        private readonly IConfiguration _configuration;
        private readonly ILogger<DirectOperationService> _logger;

        public DirectOperationService(IWebHostEnvironment environment, IConfiguration configuration, ILogger<DirectOperationService> logger)
        {
            _environment = environment;
            _configuration = configuration;
            _isProduction = _environment.IsProduction();
            _logger = logger;
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
                var error = "Expression cannot be empty.";
                _logger.LogError(error);
                throw new Exception(error);
            }
            var expression = Uri.UnescapeDataString(request?.Expression);
            double result = 0;
            try
            {
                result = await Execute(expression);
                await LogOperation(expression, result, string.Empty);
                return new OperationResponse { Expression = expression, Result = result };
            }
            catch (ExpressionException ex)
            {
                var error = ex.ToString();
                await LogOperation(expression, result, error);
                _logger.LogError(error);
                throw new Exception(error);
            }
            catch (LoggingException ex)
            {
                var error = ex.ToString();
                _logger.LogError(error);
                return new OperationResponse { Expression = expression, Result = result, Message = $"WARNING: Failed logging. Logging Error: {error}" };
            }
            catch (Exception ex)
            {
                var error = ex.ToString();
                _logger.LogError(error);
                throw new Exception(error);
            }
        }

        private string GetConnectionString()
        {
            var connectionString = _configuration["ConnectionStrings:Default"];
            var useEnvVar = _configuration.GetValue<bool>("Settings:UseEnvVar");
            if (useEnvVar)
            {
                // Windows
                connectionString = Environment.GetEnvironmentVariable("CALC_DB_CONNECTIONSTRING", EnvironmentVariableTarget.User);
                // Linux
                if(string.IsNullOrEmpty(connectionString))
                {
                    connectionString = Environment.GetEnvironmentVariable("CALC_DB_CONNECTIONSTRING");
                }
                return connectionString;
            }
            else
            {
                if (_isProduction)
                {
                    var useKeyVault = _configuration.GetValue<bool>("Settings:UseKeyVault");
                    if (useKeyVault)
                    {
                        var cred = new DefaultAzureCredential();
                        var kvUrl = $"https://{_configuration["Settings:KeyVaultName"]}.vault.azure.net";
                        var kvUri = new Uri(kvUrl);
                        var client = new SecretClient(kvUri, cred);
                        connectionString = client.GetSecret("ConnectionStrings--Default").Value.Value;
                        return connectionString;
                    }
                }
            }
            return connectionString;
        }

        public async Task<double> Execute(string expression)
        {
            try
            {
                double result = 0;
                var pattern = @"(?<n>(\d)+(\.\d+)*)";
                var expr = Regex.Replace(expression, pattern, "(double)(${n})");
                result = await CSharpScript.EvaluateAsync<double>(expr).ConfigureAwait(false);
                return result;
            }
            catch(Exception ex)
            {
                throw new ExpressionException(ex.Message, ex);
            }
        }

        private async Task LogOperation(string expression, double result, string error)
        {
            try
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
            catch (Exception ex)
            {
                throw new LoggingException(ex.Message, ex);
            }
        }

    }
}
