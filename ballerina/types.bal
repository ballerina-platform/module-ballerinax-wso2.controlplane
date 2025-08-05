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

public type RuntimeRegistrationRequest record {
    string runtimeId;
    RuntimeType runtimeType = BI;
    RuntimeStatus status = RUNNING;
    Node nodeInfo;
    Artifacts artifacts;
};

public type Heartbeat record {
    string runtimeId;
    RuntimeStatus status;
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

public type RuntimeRegistrationResponse record {
    boolean success;
    string message?;
    string[] errors?;
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

