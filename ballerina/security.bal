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

import ballerina/jwt;
import ballerina/lang.array;

final string issuer = string `https://localhost:${icpServicePort}/`;

string|error jwt = generateJwtToken();

isolated function generateJwtToken() returns string|error {
    jwt:IssuerConfig issuerConfig = {
        issuer: issuer,
        audience: "ballerina",
        username: "admin",
        expTime: 1715452200000,
        signatureConfig: {
            config: {
                keyStore: {
                    path: keyStorePath,
                    password: keyStorePassword
                },
                keyAlias: "ballerina",
                keyPassword: keyStorePassword
            }
        }
    };
    return jwt:issue(issuerConfig);
}

final jwt:ValidatorConfig & readonly validatorConfig = {
    issuer: issuer,
    audience: "ballerina",
    username: "admin",
    signatureConfig: {
        trustStoreConfig: {
            trustStore: {path: trustStorePath, password: trustStorePassword},
            certAlias: "ballerina"
        }
    }
};

isolated function authenticateRequest(string credential) returns boolean|error {
    [string, string] [username, password] = check extractUsernameAndPassword(extractCredential(credential));
    if (username == dashboard.serviceAccount && password == dashboard.serviceAccountPassword) {
        return true;
    }
    return false;
}

isolated function extractUsernameAndPassword(string credential) returns [string, string]|error {
    byte[]|error base64Decoded = 'array:fromBase64(credential);
    if base64Decoded is byte[] {
        string|error base64DecodedResults = 'string:fromBytes(base64Decoded);
        if base64DecodedResults is string {
            string[] decodedCredentials = re `:`.split(base64DecodedResults);
            if decodedCredentials.length() != 2 ||
                decodedCredentials[0].length() == 0 || decodedCredentials[1].length() == 0 {
                return error("Incorrect credential format. Format should be username:password");
            } else {
                return [decodedCredentials[0], decodedCredentials[1]];
            }
        } else {
            return error("Failed to convert byte[] credential to string.", base64DecodedResults);
        }
    } else {
        return error("Failed to convert string credential to byte[].", base64Decoded);
    }

}

isolated function extractCredential(string data) returns string {
    return re `\s`.split(data)[1];
}
