using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Calculator.Common.Configuration
{
    public static class ConfigurationExtensions
    {

        public static string GetValue(this IConfiguration configuration, string configSettingName, string configSettingVarName)
        {
            var value = configuration[configSettingName];
            var useEnvVar = false;
            bool.TryParse(configuration["Settings:UseEnvVar"], out useEnvVar);
            if (useEnvVar)
            {
                // Windows
                value = Environment.GetEnvironmentVariable(configSettingVarName, EnvironmentVariableTarget.User);
                // Linux
                if (string.IsNullOrEmpty(value))
                {
                    value = Environment.GetEnvironmentVariable(configSettingVarName);
                }
                Console.WriteLine($"{configSettingVarName}: {value}");
            }
            return value;
        }

    }
}
