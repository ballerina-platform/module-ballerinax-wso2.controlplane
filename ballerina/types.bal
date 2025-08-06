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

import ballerina/time;
import ballerina/uuid;

// === Enums ===

public enum RuntimeType {
    MI,
    BI
}

public enum RuntimeStatus {
    RUNNING,
    FAILED,
    DISABLED,
    OFFLINE,
    STOPPED
}

public enum ArtifactState {
    ENABLED,
    DISABLED,
    STARTING,
    STOPPING,
    FAILED
}

public enum ArtifactType {
    SERVICE = "services",
    LISTENER = "listeners"
}

// === Core Domain Types ===

public type Artifact record {
    string name;
};

public type Resource record {
    string[] methods;
    string url;
};

public type ListenerDetail record {
    *Artifact;
    string protocol?;
    string package;
    ArtifactState state?;
};

public type ServiceDetail record {
    *Artifact;
    string? basePath;
    string package;
    Artifact[] listeners;
    Resource[] resources;
    ArtifactState state?;
};

public type ArtifactDetail ServiceDetail|ListenerDetail;

public type Artifacts record {
    ListenerDetail[] listeners;
    ServiceDetail[] services;
};

public type Node record {
    string platformName = "ballerina";
    string platformVersion?;
    string platformHome?;
    string ballerinaHome?;
    string osName?;
    string osVersion?;
};

public type BallerinaRuntime record {
    string runtimeId;
    RuntimeType runtimeType;
    RuntimeStatus status;
    string environment?;
    string deploymentType?;
    string version?;
    Node nodeInfo;
    Artifacts artifacts;
    time:Utc registrationTime?;
    time:Utc lastHeartbeat?;
};

// === Runtime Communication Types ===

public type Heartbeat record {
    string runtimeId;
    RuntimeType runtimeType;
    RuntimeStatus status;
    string environment?;
    string deploymentType?;
    string version?;
    Node nodeInfo;
    Artifacts artifacts;
    time:Utc timestamp;
};

// === ICP Control Types ===

public type ControlCommand record {
    string commandId;
    string runtimeId;
    string targetArtifact;
    string action;
    time:Utc issuedAt;
    string status; // pending, sent, acknowledged, failed
};

public type HeartbeatResponse record {
    boolean acknowledged;
    ControlCommand[] commands?;
};

// === Configuration ===

public type IcpServer record {|
    string serverUrl;
    string authToken;
    decimal heartbeatInterval;
|};

public type Observability record {|
    string opensearchUrl;
    string logIndex;
    boolean metricsEnabled;
|};

public type IcpConfig record {|
    IcpServer icp;
    Observability observability;
|};

public type DashBoard record {
    string url;
    int heartbeatInterval = 10;
    decimal waitTimeForServicesInSeconds = 5;
    string groupId;
    string nodeId = uuid:createType4AsString();
    string mgtApiUrl;
    string serviceAccount = "bal_admin";
    string serviceAccountPassword = "bal_secret";
};

public type RequestLimit record {
    int maxUriLength;
    int maxHeaderSize;
    int maxEntityBodySize;
};

// === Summary / View Types ===

public type RuntimeSummary record {
    string runtimeId;
    RuntimeType runtimeType;
    RuntimeStatus status;
    string environment?;
    int totalServices;
    int totalListeners;
    time:Utc lastHeartbeat?;
    boolean isOnline;
};

public type IntegrationSummary record {
    string runtimeId;
    string artifactName;
    string artifactType; // service or listener
    ArtifactState state;
    string package;
};

public type ChangeNotification record {
    anydata[] deployedArtifacts;
    anydata[] undeployedArtifacts;
    anydata[] stateChangedArtifacts;
};

// === API Wrappers / Auth ===

public type UserClaims record {
    string sub;
    string[] roles;
    int exp;
};

public type ApiResponse record {
    boolean success;
    string message?;
    json data?;
    string[] errors?;
};

public type AccessTokenResponse record {|
    string AccessToken;
|};