using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Calculator.Common.Exceptions;

namespace Calculator.Common.Services
{
    public class ApiClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<ApiClient> _logger;

        public ApiClient(HttpClient httpClient, ILogger<ApiClient> logger)
        {
            _httpClient = httpClient;
            _logger = logger;
        }

        public ILogger<ApiClient> Logger
        {
            get { return _logger; }
        }

        public async Task<TResult> GetAsync<TResult>(string url, string type)
        {
            _logger.LogDebug($"ApiClientBase: Get {url}");

            var request = new HttpRequestMessage
            {
                RequestUri = new Uri(url),
                Method = HttpMethod.Get
            };

            return await SendAsync<TResult>(request, type);
        }

        public async Task<TResult> PostAsync<TResult>(string url, object data, string type)
        {
            _logger.LogDebug($"ApiClientBase: Post {url} {ApiHelper.GetLogString(data)}");

            var request = new HttpRequestMessage
            {
                RequestUri = new Uri(url),
                Method = HttpMethod.Post,
                Content = new StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json")
            };

            return await SendAsync<TResult>(request, type);
        }

        public async Task<TResult> PutAsync<TResult>(string url, object data, string type)
        {
            _logger.LogDebug($"ApiClientBase: Put {url} {ApiHelper.GetLogString(data)}");

            var request = new HttpRequestMessage
            {
                RequestUri = new Uri(url),
                Method = HttpMethod.Put,
                Content = new StringContent(JsonConvert.SerializeObject(data), Encoding.UTF8, "application/json")
            };

            return await SendAsync<TResult>(request, type);
        }

        public async Task<TResult> DeleteAsync<TResult>(string url, string type)
        {
            _logger.LogDebug($"ApiClientBase: Delete {url}");

            var request = new HttpRequestMessage
            {
                RequestUri = new Uri(url),
                Method = HttpMethod.Delete
            };

            return await SendAsync<TResult>(request, type);
        }

        public async Task<TResult> SendAsync<TResult>(HttpRequestMessage request, string type)
        {
            var response = await _httpClient.SendAsync(request);

            if (!response.IsSuccessStatusCode)
            {
                var content = await response.Content.ReadAsStringAsync();
                _logger.LogCritical(null, "ApiClientBase: StatusCode {0}; Message {1}", response.StatusCode, content);

                var ex = new ApiException(request.RequestUri.ToString(), (int)response.StatusCode, response.StatusCode.ToString(), type, content, null);
                throw ex;
            }

            var draftResponse = await response.Content.ReadAsStringAsync();

            _logger.LogDebug($"ApiClientBase: Returned {draftResponse}");

            return JsonConvert.DeserializeObject<TResult>(draftResponse);
        }
    }
}
