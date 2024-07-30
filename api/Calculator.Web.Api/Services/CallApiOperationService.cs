using Microsoft.AspNetCore.Mvc;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis.CSharp.Scripting;
using Calculator.Common.Models;
using Calculator.Common.Configuration;
using Calculator.Common.Interfaces;
using Calculator.Common.Exceptions;
using Calculator.Common.Services;
using Calculator.Web.Api.Configuration;
using static Calculator.Common.Configuration.ConfigurationExtensions;

namespace Calculator.Web.Api.Controllers
{
    public class CallApiOperationService : IOperationService
    {

        private readonly bool _isProduction;

        private readonly IWebHostEnvironment _environment;
        private readonly IConfiguration _configuration;
        private readonly ApiClient _apiClient;
        private readonly ILogger<CallApiOperationService> _logger;

        public CallApiOperationService(IWebHostEnvironment environment, IConfiguration configuration, ApiClient apiClient, ILogger<CallApiOperationService> logger)
        {
            _environment = environment;
            _configuration = configuration;
            _apiClient = apiClient;
            _isProduction = _environment.IsProduction();
            _logger = logger;
        }

        public async Task<List<OperationLog>> Get(DateTime sd, DateTime ed)
        {
            var logApiBaseUrl = _configuration.GetValue("Settings:LogApiBaseUrl", "CALC_LOGAPI_BASEURL");
            var url = $"{logApiBaseUrl}/operationlogs?sd={sd.ToString("s")}&ed={ed.ToString("s")}";
            var list = await _apiClient.GetAsync<List<OperationLog>>(url, Constants.Log);
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
            request.Expression = Uri.UnescapeDataString(request?.Expression);
            var executeApiBaseUrl = _configuration.GetValue("Settings:ExecuteApiBaseUrl", "CALC_EXECUTEAPI_BASEURL");
            var useDaprState = false;
            var sUseDaprState = _configuration.GetValue("Settings:UseDaprState", "USE_DAPR_STATE");
            bool.TryParse(sUseDaprState, out useDaprState);
            var logApiBaseUrl = _configuration.GetValue("Settings:LogApiBaseUrl", "CALC_LOGAPI_BASEURL");
            var daprStateStoreUrl = _configuration.GetValue("Settings:DaprStateStoreUrl", "DAPR_STATESTORE_URL");
            var logUrl = useDaprState ? $"{daprStateStoreUrl}" : $"{logApiBaseUrl}/operationlogs";
            double result = 0;
            var logRequest = new OperationLogRequest { Expression = request.Expression, Result = result, Error = "" };
            try
            {
                var execUrl = $"{executeApiBaseUrl}/execute";
                var response = await _apiClient.PostAsync<OperationResponse>(execUrl, request, Constants.Execute);
                result = response.Result;
                logRequest.Result = result;
                if(useDaprState)
                {
                    var id = KeyGenerator.GetKey(6);
                    var daprState = new[] { new { key = $"operationlogs-{id}", value = logRequest } };
                    await _apiClient.PostAsync<IEnumerable<object>>(logUrl, daprState, Constants.Log);
                }
                else
                {
                    await _apiClient.PostAsync<OperationLogRequest>(logUrl, logRequest, Constants.Log);
                }
                return response;
            }
            catch (ApiException ex)
            {
                var error = ex.ToString();
                _logger.LogError(error);
                switch (ex.Type)
                {
                    case Constants.Execute:
                        logRequest.Error = error;
                        if (useDaprState)
                        {
                            var id = KeyGenerator.GetKey(6);
                            var daprState = new[] { new { key = $"operationlogs-{id}", value = logRequest } };
                            await _apiClient.PostAsync<IEnumerable<object>>(logUrl, daprState, Constants.Log);
                        }
                        else
                        {
                            await _apiClient.PostAsync<OperationLogRequest>(logUrl, logRequest, Constants.Log);
                        }
                        break;
                    case Constants.Log:
                        var response = new OperationResponse { Expression = request.Expression, Result = result, Message = $"WARNING: Failed logging. Logging Error: {error}" };
                        return response;
                    default:
                        break;
                }
                throw new Exception(error);
            }
            catch (Exception ex)
            {
                var error = ex.ToString();
                _logger.LogError(error);
                throw new Exception(error);
            }
        }

    }
}
