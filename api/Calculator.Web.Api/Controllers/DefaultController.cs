using Microsoft.AspNetCore.Mvc;

namespace Calculator.Web.Api.Controllers
{
    [Route("/")]
    [ApiController]
    public class DefaultController : ControllerBase
    {
        [HttpGet]
        public IActionResult Get()
        {
            return Ok("Welcome to the Calculator API!");
        }
    }
}