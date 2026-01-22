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
import ballerina/random;
// import ballerina/random;
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

    // Initialize ICP client (JWT is generated internally from config)
    IcpClient icpClient = check new (config);
    log:printInfo("ICP agent initialized with server URL: " + config.serverUrl);

    // Start periodic heartbeat
    HeartbeatJob heartbeatJob = check new (icpClient, <decimal>config.heartbeatInterval);
    task:JobId|task:Error result = task:scheduleJobRecurByFrequency(heartbeatJob, <decimal>config.heartbeatInterval);
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
    private Heartbeat heartbeat;
    private int attemptCount = 0;

    public function init(IcpClient icpClient, decimal interval) returns error? {
        self.icpClient = icpClient;
        self.interval = interval;
        Heartbeat|error initHeartbeat = getHeartbeat();
        if (initHeartbeat is error) {
            log:printError("Failed to create heartbeat", initHeartbeat);
            return;
        }
        self.heartbeat = initHeartbeat;
    }

    # Executes the heartbeat job.
    public function execute() {

        // Create delta heartbeat with hash
        DeltaHeartbeat|error deltaHeartbeat = getDeltaHeartbeat(self.heartbeat);
        if deltaHeartbeat is error {
            log:printError("Failed to create delta heartbeat", deltaHeartbeat);
            return;
        }

        self.randomlyStopLister();
        // Send delta heartbeat first
        HeartbeatResponse|error deltaResponse = self.icpClient->sendDeltaHeartbeat(deltaHeartbeat);
        if deltaResponse is error {
            log:printError("Failed to send delta heartbeat", deltaResponse);
            return;
        }
        if !deltaResponse.acknowledged {
            return;
        }
        log:printInfo("Delta heartbeat acknowledged by ICP server");
        // Check if server requests full heartbeat
        boolean fullHeartbeatRequired = deltaResponse.fullHeartbeatRequired ?: false;
        if fullHeartbeatRequired {
            log:printInfo("ICP server requested full heartbeat");
            Heartbeat|error newHeartbeat = getHeartbeat();
            if newHeartbeat is error {
                log:printError("Failed to create full heartbeat", newHeartbeat);
                return;
            }
            self.heartbeat = newHeartbeat;
            error? fullHeartbeatResult = self.icpClient->sendHeartbeat(self.heartbeat);
            if fullHeartbeatResult is error {
                log:printError("Failed to send full heartbeat", fullHeartbeatResult);
            } else {
                log:printInfo("Full heartbeat sent successfully");
            }
        } else {
            log:printInfo("Delta heartbeat sufficient, no full heartbeat required");
            if (self.attemptCount < 2) {
                Heartbeat|error newHeartbeat = getHeartbeat();
                if newHeartbeat is error {
                    log:printError("Failed to create full heartbeat", newHeartbeat);
                    return;
                }
                self.heartbeat = newHeartbeat;
                self.attemptCount += 1;
            }
        }

    }

    function randomlyStopLister() {
        log:printInfo("Randomly deciding to start/stop listener artifact");
        float randomValue = random:createDecimal();
        log:printInfo("Generated random value: " + randomValue.toString());
        if randomValue < 0.8 && self.heartbeat.artifacts.listeners.length() > 0 {
            log:printInfo("starting listener");
            boolean|error startResult = startListenerArtifact("listener_2");
            if startResult is error {
                log:printError("Failed to start listener artifact", startResult);
            } else {
                log:printInfo("Listener artifact started successfully: " + startResult.toString());
            }
            return;
        }
        log:printInfo("stoping listener");
        log:printInfo(self.heartbeat.artifacts.listeners.toString());
        boolean|error stopResult = stopListenerArtifact("listener_2");
        if stopResult is error {
            log:printError("Failed to stop listener artifact", stopResult);
        } else {
            log:printInfo("Listener artifact stopped successfully: " + stopResult.toString());
        }
    }
}
