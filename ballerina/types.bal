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

// === Runtime Communication Types ===

public type Heartbeat record {|
    string runtimeId;
    RuntimeType runtimeType;
    RuntimeStatus status;
    string environment = environment;
    string project;
    string component;
    string version?;
    Node nodeInfo;
    Artifacts artifacts;
    string runtimeHash;
    time:Utc timestamp;
|};

public type HeartbeatForHash record {|
    string runtimeId;
    RuntimeType runtimeType;
    RuntimeStatus status;
    string environment;
    string project;
    string component;
    string version?;
    Node nodeInfo;
    Artifacts artifacts;
|};

public type DeltaHeartbeat record {|
    string runtimeId;
    string runtimeHash;
    time:Utc timestamp;
|};

// === ICP Control Types ===

public enum ControlCommandStatus {
    PENDING,
    SENT,
    ACKNOWLEDGED,
    FAILED
};

public type ControlCommand record {|
    string commandId;
    string runtimeId;
    string targetArtifact;
    string action;
    time:Utc issuedAt;
    ControlCommandStatus status; // pending, sent, acknowledged, failed
|};

public type HeartbeatResponse record {
    boolean acknowledged;
    boolean fullHeartbeatRequired?;
    ControlCommand[] commands?;
};

// === Configuration ===

public type IcpServer record {|
    string serverUrl;
    string cert;
    boolean enableSSL;
    int heartbeatInterval;
|};

public type Observability record {|
    string opensearchUrl;
    string logIndex;
    boolean metricsEnabled;
|};

public type IcpConfig record {|
    IcpServer icp;
    Observability observability;
    string keyStorePath;
    string keyStorePassword;
|};

public type RequestLimit record {
    int maxUriLength;
    int maxHeaderSize;
    int maxEntityBodySize;
};
