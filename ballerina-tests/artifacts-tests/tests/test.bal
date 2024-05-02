// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.org)
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
import ballerina/lang.value;
import ballerina/test;
import ballerinax/wso2.controlplane as cp;

configurable string testURL = ?;
configurable int testPort = ?;
string token = "";

@test:BeforeSuite
function registerClient() returns error? {
    http:Client icpClient = check new (testURL,
        auth = {
            username: "admin",
            password: "admin"
        },
        secureSocket = {
            enable: false
        }
    );
    record {
        string AccessToken;
    } result = check icpClient->/management/login();
    token = result.AccessToken;
}

@test:Config {}
public function testGetBallerinaNode() returns error? {
    http:Client mngClient = check new (testURL,
        auth = {
            token: token
        },
        secureSocket = {
            enable: false
        }
    );
    cp:Node|error node = mngClient->/management();
    test:assertTrue(node is cp:Node, "Invalid response received");
}

@test:Config {}
public function testGetBallerinaServiceArtifacts() returns error? {
    http:Client rmClient = check new (testURL,
        auth = {
            token: token
        },
        secureSocket = {
            enable: false
        }
    );
    cp:Artifacts|error result = rmClient->/management/services();
    test:assertTrue(result is cp:Artifacts, "Invalid response received");
    test:assertTrue(result.count() == 1, "No services found");
    if (result is cp:Artifacts) {
        test:assertEquals(result.list[0].name, "service_1", "Invalid service name received");
    }
    cp:ArtifactDetail|error artifact = rmClient->/management/services(name = "service_1");
    test:assertTrue(artifact is cp:ServiceDetail, "Invalid response received");
    if (artifact is cp:ServiceDetail) {
        test:assertEquals(artifact.name, "service_1", "Invalid service name received");
        test:assertEquals(artifact.basePath, "/hello", "Invalid service basePath received");
        test:assertEquals(artifact.package, "ballerinax/artifacts_tests:0", "Invalid service package received");
        test:assertEquals(artifact.listeners.toString(), string `[{"name":"listener_1"}]`, "Invalid service listener received");
        test:assertEquals(artifact.resources.toString(), string `[{"methods":["get"],"url":"/greeting"},{"methods":["get"],"url":"/albums/{title}/{user}/*"}]`, "Invalid service resources received");
    }
}

@test:Config {}
public function testGetBallerinaListenerArtifacts() returns error? {
    http:Client rmClient = check new (testURL,
        secureSocket = {
            enable: false
        },
        auth = {
            token: token
        }
    );
    cp:Artifacts|error result = rmClient->/management/listeners();
    test:assertTrue(result is cp:Artifacts, "Invalid response received");
    test:assertTrue(result.count() == 1, "No listeners found");
    if (result is cp:Artifacts) {
        test:assertEquals(result.list[0].name, "listener_1", "Invalid listener name received");
    }
    cp:ArtifactDetail|error artifact = rmClient->/management/listeners(name = "listener_1");
    test:assertTrue(artifact is cp:ListenerDetail, "Invalid response received");
    if (artifact is cp:ListenerDetail) {
        test:assertEquals(artifact.name, "listener_1", "Invalid listener name received");
        test:assertEquals(artifact.protocol, "HTTP", "Invalid listener protocol received");
        test:assertEquals(artifact.package, "ballerina/http:2", "Invalid listener package received");
        test:assertEquals(artifact["requestLimits"].toString(), string `{"maxUriLength":4096,"maxHeaderSize":8192,"maxEntityBodySize":-1}`, "Invalid listener requestLimits received");
        test:assertEquals(artifact["httpVersion"], "2.0", "Invalid listener httpVersion received");
        test:assertEquals(artifact["port"], 9090, "Invalid listener port received");
        test:assertEquals(artifact["host"], "0.0.0.0", "Invalid listener host received");
        test:assertEquals(artifact["timeout"], 60, "Invalid listener timeout received");
    }
}

@test:Config {}
function testNegativeRegisterClient() returns error? {
    http:Client icpClient = check new (testURL,
        auth = {
            username: "Non-admin",
            password: "Non-admin"
        },
        secureSocket = {
            enable: false
        }
    );
    anydata|error result = icpClient->/management/login();
    test:assertTrue(result is error, "Invalid response received");
    error e = <error>result;
    map<value:Cloneable> & readonly detail = e.detail();
    value:Cloneable & readonly unionResult = detail["body"];
    test:assertTrue(unionResult is map<value:Cloneable>, "Invalid response received");
    if (unionResult is map<value:Cloneable>) {
        test:assertEquals(unionResult["message"], "Invalid credentials", "Invalid error message received");
    }
    test:assertEquals(e.message(), "Internal Server Error", "Invalid error message received");
}

@test:Config {}
function testNegativeInvalidTokenNode() returns error? {
    http:Client rmClient = check new (testURL,
        secureSocket = {
            enable: false
        },
        auth = {
            token: "Invalid-token"
        }
    );
    cp:Node|error node = rmClient->/management();
    test:assertTrue(node is error, "Invalid response received");
    error e = <error>node;
    map<value:Cloneable> & readonly detail = e.detail();
    value:Cloneable & readonly unionResult = detail["body"];
    test:assertTrue(unionResult is map<value:Cloneable>, "Invalid response received");
    if (unionResult is map<value:Cloneable>) {
        test:assertEquals(unionResult["message"], "Invalid JWT.", "Invalid error message received");
    }
    test:assertEquals(e.message(), "Internal Server Error", "Invalid error message received");
}

@test:Config {}
function testNegativeInvalidTokenArtifacts() returns error? {
    http:Client rmClient = check new (testURL,
        secureSocket = {
            enable: false
        },
        auth = {
            token: "Invalid-token"
        }
    );
    cp:Artifacts|error node = rmClient->/management/services();
    test:assertTrue(node is error, "Invalid response received");
    error e = <error>node;
    map<value:Cloneable> & readonly detail = e.detail();
    value:Cloneable & readonly unionResult = detail["body"];
    test:assertTrue(unionResult is map<value:Cloneable>, "Invalid response received");
    if (unionResult is map<value:Cloneable>) {
        test:assertEquals(unionResult["message"], "Invalid JWT.", "Invalid error message received");
    }
    test:assertEquals(e.message(), "Internal Server Error", "Invalid error message received");
}
