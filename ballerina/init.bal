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
import ballerina/lang.runtime;
import ballerina/log;

function init() returns error? {
    worker w1 returns error? {
        check registerInDashboardServer();
    }
}

function registerInDashboardServer() returns error? {
    if dashboard.url == "" {
        return;
    }
    // We need to wait until services are up
    runtime:sleep(dashboard.waitTimeForServicesInSeconds);
    http:Client dsClient = check new (dashboard.url,
        secureSocket = {
            enable: false
        }
    );

    IntegrationPlaneConnectionRequest connectionRequest = {
        groupId: dashboard.groupId,
        nodeId: dashboard.nodeId,
        interval: dashboard.heartbeatInterval,
        mgtApiUrl: dashboard.mgtApiUrl
    };

    boolean isFailed = true;
    while (true) {
        http:Response|http:ClientError resp = dsClient->post("/heartbeat", connectionRequest);
        if (resp is http:ClientError) {
            log:printError(string `Connection to dashboard server ${dashboard.url} is failed due to http error ${resp.toString()}. Retrying after ${dashboard.heartbeatInterval} seconds.`);
            isFailed = true;
        } else if (resp.statusCode != 200) {
            string|http:ClientError textPayload = resp.getTextPayload();
            if textPayload is string {
                log:printError(string `Connection to dashboard server ${dashboard.url} is failed due to ${textPayload} with error code ${resp.statusCode}. Retrying after ${dashboard.heartbeatInterval} seconds.`);
            } else {
                log:printError(string `Connection to dashboard server ${dashboard.url} is failed due to client error ${textPayload.message()}. Retrying after ${dashboard.heartbeatInterval} seconds.`);
            }
            isFailed = true;
        } else if (isFailed) {
            log:printInfo(string `Connected to dashboard server ${dashboard.url}`);
            isFailed = false;
        }
        runtime:sleep(<decimal>dashboard.heartbeatInterval);
    }
}
