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

import ballerina/http;
import ballerina/jballerina.java;
import ballerina/jwt;

listener http:Listener securedEP = new (icpServicePort,
    secureSocket = {
        key: {
            path: keyStorePath,
            password: keyStorePassword
        }
    }
);

service /management on securedEP {

    isolated resource function get login(@http:Header string Authorization) returns AccessTokenResponse|error {
        boolean isValid = check authenticateRequest(Authorization);
        if (!isValid) {
            return error http:ClientAuthError("Invalid credentials");
        }
        return {AccessToken: check generateJwtToken()};
    }

    isolated resource function get .(@http:Header string Authorization) returns Node|error {
        _ = check jwt:validate(extractCredential(Authorization), validatorConfig);
        return check getBallerinaNode();
    }

    isolated resource function get [ArtifactType resourceType](string? name, @http:Header string Authorization)
                                            returns Artifacts|ArtifactDetail|error {
        _ = check jwt:validate(extractCredential(Authorization), validatorConfig);
        if (name == ()) {
            Artifact[] artifacts = check getArtifacts(resourceType, Artifact);
            return {
                count: artifacts.length(),
                list: artifacts
            };
        }
        return getDetailedArtifact(resourceType, name);
    }
}

isolated function getBallerinaNode() returns Node|error = @java:Method {
    'class: "io.ballerina.lib.wso2.controlplane.Utils"
} external;

isolated function getDetailedArtifact(string resourceType, string name) returns ArtifactDetail|error =
@java:Method {
    'class: "io.ballerina.lib.wso2.controlplane.Artifacts"
} external;

isolated function getArtifacts(string resourceType, typedesc<anydata> t) returns Artifact[]|error =
@java:Method {
    'class: "io.ballerina.lib.wso2.controlplane.Artifacts"
} external;
