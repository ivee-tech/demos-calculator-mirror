using Calculator.Web.Api.Models;

namespace Calculator.Web.Api.Services
{
    public interface IOperationService
    {
        Task<List<OperationLog>> Get(DateTime sd, DateTime ed);
        Task<OperationResponse> ExecuteAndLogOperation(OperationRequest request);
    }
}
