// Copyright (c) 2025, WSO2 LLC. (https://www.wso2.com).
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

import ballerina/lang.runtime;
import ballerina/log;
import ballerina/task;

function init() returns error? {
    worker w1 returns error? {
        check startICPAgent();
    }
}

function startICPAgent() returns error? {
    log:printInfo("Starting ICP agent...");

    // Load configuration
    IcpConfig config = check loadConfig();
    log:printInfo("Loaded ICP configuration: " + config.toJsonString());

    // Initialize ICP client
    IcpClient icpClient = check new (config);
    log:printInfo("ICP agent initialized with server URL: " + config.icp.serverUrl);

    // Start periodic heartbeat
    HeartbeatJob heartbeatJob = new (icpClient, config.icp.heartbeatInterval);
    task:JobId|task:Error result = task:scheduleJobRecurByFrequency(heartbeatJob, config.icp.heartbeatInterval);
    if result is task:Error {
        log:printError("Failed to start heartbeat job", result);
        return error("Heartbeat scheduling failed");
    }

    log:printInfo("ICP agent started successfully with job ID: " + result.toString());

    // Keep the main function running to allow periodic tasks to execute
    while true {
        // Sleep for a while to prevent busy waiting
        runtime:sleep(1000);
    }
}

// Heartbeat job
public class HeartbeatJob {
    *task:Job;
    private final IcpClient icpClient;
    private final decimal interval;

    public function init(IcpClient icpClient, decimal interval) {
        self.icpClient = icpClient;
        self.interval = interval;
    }

    # Executes the heartbeat job.
    public function execute() {
        // Get current integration status
        Heartbeat|error heartbeat = getHeartbeat();
        if heartbeat is error {
            log:printError("Failed to create heartbeat", heartbeat);
            return;
        }
        error? result = self.icpClient->sendHeartbeat(heartbeat);
        if result is error {
            log:printError("Failed to send heartbeat", result);
        }
    }
}
