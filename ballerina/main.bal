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
    log:printInfo("Starting ICP agent...");

    // Load configuration
    IcpConfig config = check loadConfig();
    log:printInfo("Loaded ICP configuration: " + config.toJsonString());

    // Initialize ICP client (JWT is generated internally from config)
    IcpClient icpClient = check new (config);
    log:printInfo("ICP agent initialized with server URL: " + config.serverUrl);

    worker w1 returns error? {
        check startICPAgent(icpClient, config);
    }

}

function startICPAgent(IcpClient icpClient, IcpConfig config) returns error? {
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
    private int attemptCount = 0;
    private Heartbeat heartbeat;
    private boolean fullHeartbeatRequired = true;

    public function init(IcpClient icpClient, decimal interval) returns error? {
        self.icpClient = icpClient;
        self.interval = interval;
        self.heartbeat = check getHeartbeat();
    }

    # Executes the heartbeat job.
    public function execute() {

        HeartbeatResponse|error heartbeatResponse;
        if (self.fullHeartbeatRequired) {
            Heartbeat|error newHeartbeat = getHeartbeat();
            if newHeartbeat is error {
                log:printError("Failed to create full heartbeat", newHeartbeat);
                return;
            }
            self.heartbeat = newHeartbeat;
            log:printInfo("Sending full heartbeat to ICP server");
            heartbeatResponse = self.icpClient->sendHeartbeat(self.heartbeat);
        } else {
            // Create delta heartbeat with hash
            DeltaHeartbeat|error deltaHeartbeat = getDeltaHeartbeat(self.heartbeat);
            if deltaHeartbeat is error {
                log:printError("Failed to create delta heartbeat", deltaHeartbeat);
                return;
            }
            log:printInfo("Sending delta heartbeat to ICP server");
            heartbeatResponse = self.icpClient->sendDeltaHeartbeat(deltaHeartbeat);
        }
        if heartbeatResponse is error {
            log:printError("Heartbeat response error", heartbeatResponse);
            return;
        }
        if !heartbeatResponse.acknowledged {
            return;
        }
        self.fullHeartbeatRequired = heartbeatResponse.fullHeartbeatRequired ?: false;
        log:printInfo("Heartbeat acknowledged by ICP server");
        self.handleControlCommands(heartbeatResponse.commands);
    }

    function handleControlCommands(ControlCommand[] commands) {
        if commands.length() == 0 {
            return;
        }

        boolean artifactsChanged = false;
        foreach ControlCommand command in commands {
            log:printInfo(string `Handling control command: ${command.toJsonString()}`);
            command.status = PENDING;

            string artifactName = command.targetArtifact.name;
            boolean isStart = command.action == START;
            string action = isStart ? "start" : "stop";

            log:printInfo(string `${isStart ? "Starting" : "Stopping"} listener: ${artifactName}`);

            // Execute the control action
            boolean|error result = isStart
                ? startListenerArtifact(artifactName)
                : stopListenerArtifact(artifactName);

            if result is error {
                log:printError(string `Failed to ${action} listener: ${artifactName}`, result);
                command.status = FAILED;
                continue; // Don't update state if operation failed
            }

            // Update artifact state only if operation succeeded
            log:printInfo(string `Successfully ${action}ed listener: ${artifactName}`);
            artifactsChanged = true;
            command.status = COMPLETED;
        }

        if artifactsChanged {
            Heartbeat|error newHeartbeat = getHeartbeat();
            if newHeartbeat is error {
                log:printError("Failed to create full heartbeat after control command", newHeartbeat);
                return;
            }
            self.heartbeat = newHeartbeat;
        }
    }
}
