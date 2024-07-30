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
    public class PubSubOperationService : IOperationService
    {

        private readonly bool _isProduction;

        private readonly IWebHostEnvironment _environment;
        private readonly IConfiguration _configuration;
        private readonly ApiClient _apiClient;
        private readonly ILogger<PubSubOperationService> _logger;

        public PubSubOperationService(IWebHostEnvironment environment, IConfiguration configuration, ApiClient apiClient, ILogger<PubSubOperationService> logger)
        {
            _environment = environment;
            _configuration = configuration;
            _apiClient = apiClient;
            _isProduction = _environment.IsProduction();
            _logger = logger;
        }

        public async Task<List<OperationLog>> Get(DateTime sd, DateTime ed)
        {
            throw new NotImplementedException();
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
            var daprStateStoreUrl = _configuration.GetValue("Settings:DaprPubSubUrl", "DAPR_PUBSUB_URL");
            var logUrl = $"{daprStateStoreUrl}";
            double result = 0;
            var logRequest = new OperationLogRequest { Expression = request.Expression, Result = result, Error = "" };
            try
            {
                var execUrl = $"{executeApiBaseUrl}/execute";
                var response = await _apiClient.PostAsync<OperationResponse>(execUrl, request, Constants.Execute);
                result = response.Result;
                logRequest.Result = result;
                await _apiClient.PostAsync<OperationLogRequest>(logUrl, logRequest, Constants.Log);
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
                        await _apiClient.PostAsync<OperationLogRequest>(logUrl, logRequest, Constants.Log);
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
