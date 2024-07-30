using Microsoft.AspNetCore.Mvc;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using System.Data.SqlClient;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis.CSharp.Scripting;
using Calculator.Common.Models;
using Calculator.Common.Configuration;
using Calculator.Common.Interfaces;

// For more information on enabling Web API for empty projects, visit https://go.microsoft.com/fwlink/?LinkID=397860

namespace Calculator.Web.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OperationController : ControllerBase
    {

        private readonly IWebHostEnvironment _env;
        private readonly IConfiguration _configuration;
        private readonly IOperationService _operationService;

        public OperationController(IWebHostEnvironment env, IConfiguration configuration, IOperationService operationService)
        {
            _env = env;
            _configuration = configuration;
            _operationService = operationService;
        }

        [HttpGet]
        public async Task<IActionResult> Get(DateTime sd, DateTime ed)
        {
            // var opSvc = new OperationService(_env.IsProduction(), _configuration);
            var list = await _operationService.Get(sd, ed);
            return Ok(list);
        }

        [HttpPost("execute")]
        public async Task<IActionResult> ExecuteAndLogOperation(OperationRequest request)
        {
            if(string.IsNullOrEmpty(request?.Expression))
            {
                return BadRequest("Expression cannot be empty.");
            }
            try
            {
                var response = await _operationService.ExecuteAndLogOperation(request);
                return Ok(response);
            }
            catch (Exception ex)
            {
                return Problem(ex.ToString());
            }
        }

    }
}
