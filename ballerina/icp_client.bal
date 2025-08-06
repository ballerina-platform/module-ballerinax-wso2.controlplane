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

public client class IcpClient {
    private final http:Client httpClient;
    private final IcpConfig config;

    public function init(IcpConfig config) returns http:ClientError? {
        self.config = config;
        self.httpClient = check new (config.icp.serverUrl, retryConfig = {
            count: 3,
            interval: 5,
            backOffFactor: 2.0
        });
    }

    // Send heartbeat to ICP server
    isolated remote function sendHeartbeat(Heartbeat heartbeat) returns error? {
        http:Request request = new;
        request.setHeader("Authorization", string `Bearer ${self.config.icp.authToken}`);
        request.setPayload(heartbeat);

        HeartbeatResponse heartbeatResponse = check self.httpClient->post("/icp/heartbeat", request);
        if heartbeatResponse.acknowledged {
            log:printInfo("Heartbeat acknowledged by ICP server");
            if heartbeatResponse.commands is ControlCommand[] {
                log:printInfo("Received control commands: " + heartbeatResponse.commands.toJsonString());
                // Process control commands if needed
            }
        } else {
            log:printError("Heartbeat not acknowledged by ICP server");
            return error("Heartbeat not acknowledged");
        }
    }
}
