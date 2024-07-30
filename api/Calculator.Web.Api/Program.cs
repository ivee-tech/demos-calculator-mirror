using Calculator.Web.Api.Controllers;
using Calculator.Common.Interfaces;
using Calculator.Common.Models;
using Calculator.Common.Services;
using Polly.Extensions.Http;
using Polly;
using Calculator.Common.Exceptions;

var builder = WebApplication.CreateBuilder(args);
builder.Logging.ClearProviders();
builder.Logging.AddConsole();

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors();
CallType callType = CallType.Direct;
Enum.TryParse<CallType>(builder.Configuration["Settings:CallType"], out callType);
switch(callType)
{
    case CallType.CallApi:
        builder.Services.AddHttpClient<ApiClient>()
            .AddPolicyHandler(GetRetryPolicy())
            .SetHandlerLifetime(TimeSpan.FromMinutes(5))  //Set lifetime to five minutes
            ;
        builder.Services.AddSingleton<ApiClient>();
        builder.Services.AddScoped<IOperationService, CallApiOperationService>();
        break;
    case CallType.PubSub:
        builder.Services.AddHttpClient();
        builder.Services.AddSingleton<ApiClient>();
        builder.Services.AddScoped<IOperationService, PubSubOperationService>();
        break;
    case CallType.Direct:
    default:
        builder.Services.AddScoped<IOperationService, DirectOperationService>();
        break;
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors(x => x.AllowAnyHeader()
      .AllowAnyMethod()
      .AllowAnyOrigin());

app.UseAuthorization();

app.MapControllers();

app.Run();


static IAsyncPolicy<HttpResponseMessage> GetRetryPolicy()
{
    return HttpPolicyExtensions
        .HandleTransientHttpError()
        //.OrResult(msg => msg.StatusCode == System.Net.HttpStatusCode.NotFound 
        //    || msg.StatusCode == System.Net.HttpStatusCode.BadRequest
        //    || msg.StatusCode == System.Net.HttpStatusCode.InternalServerError)
        .Or<HttpRequestException>()
        .WaitAndRetryAsync(6, retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)));
}