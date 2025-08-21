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

import ballerina/http;
import ballerina/log;

# ICP Client
# This client is responsible for communicating with the ICP server to send heartbeats and receive control commands
public client class IcpClient {
    private final http:Client httpClient;
    private final string jwtToken;

    public function init(IcpConfig config) returns http:ClientError? {
        self.httpClient = check new (config.icp.serverUrl,
            secureSocket = {
                cert: cert,
                enable: enableSSL
            },
            retryConfig = {
                count: 2,
                interval: 5,
                backOffFactor: 2.0
            }
        );
    }

    // Send delta heartbeat to ICP server
    isolated remote function sendDeltaHeartbeat(DeltaHeartbeat deltaHeartbeat) returns HeartbeatResponse|error {
        http:Request request = new;

        request.setHeader(http:AUTH_HEADER, string `${http:AUTH_SCHEME_BEARER} ${check generateJwtToken()}`);
        request.setPayload(deltaHeartbeat);
        log:printInfo("Sending delta heartbeat to ICP server");

        HeartbeatResponse heartbeatResponse = check self.httpClient->post("/icp/deltaHeartbeat", request);
        if heartbeatResponse.acknowledged {
            log:printInfo("Delta heartbeat acknowledged by ICP server");
            if heartbeatResponse.commands is ControlCommand[] {
                log:printInfo("Received control commands: " + heartbeatResponse.commands.toJsonString());
            }
        } else {
            log:printError("Delta heartbeat not acknowledged by ICP server");
        }
        return heartbeatResponse;
    }

    // Send full heartbeat to ICP server
    isolated remote function sendHeartbeat(Heartbeat heartbeat) returns error? {
        http:Request request = new;
        request.setHeader(http:AUTH_HEADER, string `${http:AUTH_SCHEME_BEARER} ${check generateJwtToken()}`);
        request.setPayload(heartbeat);
        log:printInfo("Sending full heartbeat to ICP server");

        HeartbeatResponse heartbeatResponse = check self.httpClient->post("/icp/heartbeat", request);
        if heartbeatResponse.acknowledged {
            log:printInfo("Full heartbeat acknowledged by ICP server");
            if heartbeatResponse.commands is ControlCommand[] {
                log:printInfo("Received control commands: " + heartbeatResponse.commands.toJsonString());
            }
        } else {
            log:printError("Full heartbeat not acknowledged by ICP server");
            return error("Heartbeat not acknowledged");
        }
    }
}
