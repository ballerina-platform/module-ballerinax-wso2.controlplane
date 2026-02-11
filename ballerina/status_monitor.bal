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

import ballerina/crypto;
import ballerina/file;
import ballerina/io;
import ballerina/jballerina.java;
import ballerina/observe;
import ballerina/time;
import ballerina/uuid;

configurable string runtimeIdFile = ".icp_runtime_id";

// Initialize runtime ID once at module load time
final string currentRuntimeId = check initializeRuntimeId();
var _ = check observe:addTag("icp.runtimeId", currentRuntimeId);

// Initialize runtime ID - check file first, then generate if needed
isolated function initializeRuntimeId() returns string|error {
    // Use current working directory for the runtime ID file
    string runtimeIdPath = runtimeIdFile;

    // Check if file exists and read the runtime ID first
    if check file:test(runtimeIdPath, file:EXISTS) {
        string existingId = check io:fileReadString(runtimeIdPath);
        // Validate it's not empty and within valid length (max 100 chars)
        string trimmedId = existingId.trim();
        if trimmedId.length() > 0 && trimmedId.length() <= 100 {
            return trimmedId;
        }
    }

    // Generate new runtime ID if file doesn't exist or is invalid
    string newRuntimeId;
    if runtime.trim().length() > 0 {
        // If configurable ID is provided, append a UUID to it
        string baseId = runtime.trim();
        string generatedUuid = uuid:createType1AsString();
        // Format: {providedId}-{uuid} to ensure uniqueness while preserving the base ID
        newRuntimeId = string `${baseId}-${generatedUuid}`;

        // Ensure it doesn't exceed 100 characters
        if newRuntimeId.length() > 100 {
            newRuntimeId = newRuntimeId.substring(0, 100);
        }
    } else {
        // Generate a full UUID if no configurable ID provided
        newRuntimeId = uuid:createType1AsString();
    }

    check io:fileWriteString(runtimeIdPath, newRuntimeId);
    return newRuntimeId;
}

isolated function getHeartbeat() returns Heartbeat|error {
    // First create heartbeat data without hash and timestamp
    HeartbeatForHash heartbeatForHash = {
        runtime: currentRuntimeId,
        runtimeType: BI,
        status: RUNNING,
        nodeInfo: check getBallerinaNode(),
        environment: environment,
        project: project,
        component: integration,
        artifacts: {
            listeners: check getListenerDetails(),
            services: check getServiceDetails(),
            main: check getMainArtifact()
        }
    };

    // Calculate hash from the heartbeat content (excluding timestamp)
    string heartbeatContent = heartbeatForHash.toJsonString();
    string runtimeHash = calculateSimpleHash(heartbeatContent);

    // Create full heartbeat with hash and timestamp
    Heartbeat heartbeat = {
        runtime: heartbeatForHash.runtime,
        runtimeType: heartbeatForHash.runtimeType,
        status: heartbeatForHash.status,
        nodeInfo: heartbeatForHash.nodeInfo,
        environment: heartbeatForHash.environment,
        project: heartbeatForHash.project,
        component: heartbeatForHash.component,
        version: heartbeatForHash.version,
        artifacts: heartbeatForHash.artifacts,
        runtimeHash: runtimeHash,
        timestamp: time:utcNow()
    };

    return heartbeat;
}

isolated function getDeltaHeartbeat(Heartbeat heartbeat) returns DeltaHeartbeat|error {
    DeltaHeartbeat deltaHeartbeat = {
        runtime: heartbeat.runtime,
        runtimeHash: heartbeat.runtimeHash,
        timestamp: heartbeat.timestamp
    };
    return deltaHeartbeat;
}

isolated function calculateSimpleHash(string content) returns string {
    return crypto:hashMd5(content.toBytes()).toBase64();
}

isolated function getListenerDetails() returns ListenerDetail[]|error {
    Artifact[] artifacts = check getListeners();
    return artifacts.map(artifact => <ListenerDetail>check getDetailedArtifact(LISTENER, artifact.name));
}

isolated function getServiceDetails() returns ServiceDetail[]|error {
    Artifact[] artifacts = check getServices();
    return artifacts.map(artifact => <ServiceDetail>check getDetailedArtifact(SERVICE, artifact.name));
}

isolated function getServices() returns Artifact[]|error {
    Artifact[] artifacts = check getArtifacts(SERVICE, Artifact);
    return artifacts;
}

isolated function getListeners() returns Artifact[]|error {
    Artifact[] artifacts = check getArtifacts(LISTENER, Artifact);
    return artifacts;
}

isolated function getBallerinaNode() returns Node|error = @java:Method {
    'class: "io.ballerina.lib.wso2.icp.Utils"
} external;

isolated function getDetailedArtifact(string resourceType, string name) returns ArtifactDetail|error =
@java:Method {
    'class: "io.ballerina.lib.wso2.icp.Artifacts"
} external;

isolated function getArtifacts(string resourceType, typedesc<anydata> t) returns Artifact[]|error =
@java:Method {
    'class: "io.ballerina.lib.wso2.icp.Artifacts"
} external;

isolated function getMainArtifact() returns MainDetail|error =
@java:Method {
    'class: "io.ballerina.lib.wso2.icp.Artifacts"
} external;

isolated function stopListenerArtifact(string name) returns boolean|error =
@java:Method {
    'class: "io.ballerina.lib.wso2.icp.Artifacts"
} external;

isolated function startListenerArtifact(string name) returns boolean|error =
@java:Method {
    'class: "io.ballerina.lib.wso2.icp.Artifacts"
} external;
