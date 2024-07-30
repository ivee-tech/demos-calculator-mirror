using Calculator.Common.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Calculator.Common.Interfaces
{
    public interface IOperationService
    {
        Task<List<OperationLog>> Get(DateTime sd, DateTime ed);
        Task<OperationResponse> ExecuteAndLogOperation(OperationRequest request);
    }
}
