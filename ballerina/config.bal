// Copyright (c) 2025, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

configurable string serverUrl = "https://localhost:9445";
configurable int heartbeatInterval = 10;
configurable string opensearchURL = "";
configurable string logIndex = "bi-client-logs";
configurable boolean metricsEnabled = false;
configurable string cert = "";
configurable boolean enableSSL = false;

// jwt configuration
configurable string jwtIssuer = "icp-runtime-jwt-issuer";
configurable string|string[] jwtAudience = "icp-server";
configurable string privateKeyFile = "./resources/keys/private.key";
configurable decimal jwtExpiryTimeSeconds = 3600;

configurable string runtime = "";
configurable string environment = "Dev";
configurable string integration = "default_integration";
configurable string project = "default_project";
configurable string defaultRuntimeJwtHMACSecret = "default-secret-key-at-least-32-characters-long-for-hs256";

public function loadConfig() returns IcpConfig|error {
    IcpConfig config = {
        icp: {
            serverUrl: serverUrl,
            heartbeatInterval: heartbeatInterval,
            cert: cert,
            enableSSL: enableSSL
        },
        observability: {
            opensearchUrl: opensearchURL,
            logIndex: logIndex,
            metricsEnabled: metricsEnabled
        }
    };
    return config;
}
