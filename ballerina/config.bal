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

import ballerina/file;
import ballerina/os;

configurable string serverUrl = "https://localhost:8080";
configurable string authToken = "";
configurable decimal heartbeatInterval = 10.0;
configurable string opensearchURL = "";
configurable string logIndex = "bi-client-logs";
configurable boolean metricsEnabled = false;
configurable string cert = "";
configurable boolean enableSSL = false;

// configurable DashBoard dashboard = ?;
configurable string keyStorePath = check getDefaultKeyStore();
configurable string keyStorePassword = "ballerina";
configurable string trustStorePath = check getDefaultTrustStore();
configurable string trustStorePassword = "ballerina";

configurable string runtimeId = ?;
configurable string environment = "Development";

function getDefaultTrustStore() returns string|error {
    string trustStorePath = check file:joinPath(os:getEnv("BALLERINA_HOME"), "bre", "security", "ballerinaTruststore.p12");
    return trustStorePath;
}

function getDefaultKeyStore() returns string|error {
    string keyStorePath = check file:joinPath(os:getEnv("BALLERINA_HOME"), "bre", "security", "ballerinaKeystore.p12");
    return keyStorePath;
}

public function loadConfig() returns IcpConfig|error {
    IcpConfig config = {
        icp: {
            serverUrl: serverUrl,
            authToken: authToken,
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
