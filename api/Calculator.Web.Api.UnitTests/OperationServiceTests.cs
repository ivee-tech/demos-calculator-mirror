using Calculator.Web.Api.Controllers;
using Microsoft.CodeAnalysis.Scripting;
using Microsoft.Extensions.Configuration;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System;
using System.Threading.Tasks;

namespace Calculator.Web.Api.UnitTests
{
    [TestClass]
    public class OperationServiceTests
    {

        private IConfiguration _config;

        public OperationServiceTests()
        {
           _config = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json")
                .Build();
        }

        [TestMethod]
        public async Task TestExpr1()
        {
            var opSvc = new OperationService(false, _config);
            var expr = "1 + 2";
            var actual = 3;
            var expected = await opSvc.Execute(expr);
            Assert.AreEqual(expected, actual);
        }

        [TestMethod]
        public async Task TestExpr2()
        {
            var opSvc = new OperationService(false, _config);
            var expr = "3 * 4";
            var actual = 12;
            var expected = await opSvc.Execute(expr);
            Assert.AreEqual(expected, actual);
        }

        [TestMethod]
        public async Task TestExpr3()
        {
            var opSvc = new OperationService(false, _config);
            var expr = "5 - 6";
            var actual = -1;
            var expected = await opSvc.Execute(expr);
            Assert.AreEqual(expected, actual);
        }

        [TestMethod]
        public async Task TestExpr4()
        {
            var opSvc = new OperationService(false, _config);
            var expr = "8 / 4";
            var actual = 2;
            var expected = await opSvc.Execute(expr);
            Assert.AreEqual(expected, actual);
        }

        [TestMethod]
        public void TestExpr5()
        {
            var opSvc = new OperationService(false, _config);
            var expr = " 1 - (3 + 4";
            Assert.ThrowsExceptionAsync<CompilationErrorException>(async () =>
            {
                var expected = await opSvc.Execute(expr);
            });
        }
    }
}