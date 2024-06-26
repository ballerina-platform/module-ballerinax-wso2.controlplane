// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com).
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/file;
import ballerina/os;

configurable DashBoard dashboard = ?;
configurable string keyStorePath = check getDefaultKeyStore();
configurable string keyStorePassword = "ballerina";
configurable string trustStorePath = check getDefaultTrustStore();
configurable string trustStorePassword = "ballerina";

function getDefaultTrustStore() returns string|error {
    string trustStorePath = check file:joinPath(os:getEnv("BALLERINA_HOME"), "bre", "security", "ballerinaTruststore.p12");
    return trustStorePath;
}

configurable int icpServicePort = 9264;

function getDefaultKeyStore() returns string|error {
    string keyStorePath = check file:joinPath(os:getEnv("BALLERINA_HOME"), "bre", "security", "ballerinaKeystore.p12");
    return keyStorePath;
}
