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

import ballerina/uuid;

# Represents the ICP server configuration.
#
# + serverUrl - the URL of the ICP server
# + authToken - the authentication token for ICP server communication
# + heartbeatInterval - the interval in seconds between heartbeat messages
public type IcpServer record {|
    string serverUrl;
    string authToken;
    decimal heartbeatInterval;
|};

# Represents the observability configuration for monitoring and logging.
#
# + opensearchUrl - the URL of the OpenSearch instance for log storage
# + logIndex - the index name for storing logs in OpenSearch
# + metricsEnabled - flag to enable or disable metrics collection
public type Observability record {|
    string opensearchUrl;
    string logIndex;
    boolean metricsEnabled;
|};

# Represents the complete ICP configuration.
#
# + icp - the ICP server configuration
# + observability - the observability configuration
public type IcpConfig record {|
    IcpServer icp;
    Observability observability;
|};

# Represents a change notification for artifact lifecycle events.
#
# + deployedArtifacts - list of newly deployed artifacts
# + undeployedArtifacts - list of undeployed artifacts
# + stateChangedArtifacts - list of artifacts that changed state
type ChangeNotification record {
    anydata[] deployedArtifacts;
    anydata[] undeployedArtifacts;
    anydata[] stateChangedArtifacts;
};

# Represents the response containing an access token.
#
# + AccessToken - the access token for authentication
type AccessTokenResponse record {|
    string AccessToken;
|};

# Represents the dashboard configuration.
#
# + url - the dashboard URL
# + heartbeatInterval - the interval for heartbeat messages (default: 10)
# + waitTimeForServicesInSeconds - wait time for services to start (default: 5)
# + groupId - the group identifier
# + nodeId - the unique node identifier (auto-generated UUID)
# + mgtApiUrl - the management API URL
# + serviceAccount - the service account username (default: "bal_admin")
# + serviceAccountPassword - the service account password (default: "bal_secret")
type DashBoard record {
    string url;
    int heartbeatInterval = 10;
    decimal waitTimeForServicesInSeconds = 5;
    string groupId;
    string nodeId = uuid:createType4AsString();
    string mgtApiUrl;
    string serviceAccount = "bal_admin";
    string serviceAccountPassword = "bal_secret";
};

# Represents a list of artifacts in a Ballerina node.
#
# + listeners - the list of listener artifacts
# + services - the list of service artifacts
public type Artifacts record {
    ListenerDetail[] listeners;
    ServiceDetail[] services;
};

# Enumeration of supported artifact types.
public enum ArtifactType {
    SERVICE = "services",
    LISTENER = "listeners"
}

# Represents a Ballerina artifact.
#
# + name - the name of the artifact
public type Artifact record {
    string name;
};

# Union type representing the details of a Ballerina artifact.
# Can be either ServiceDetail or ListenerDetail.
public type ArtifactDetail ServiceDetail|ListenerDetail;

# Represents the details of a Ballerina service.
#
# + basePath - the base path of the service  
# + package - the package where the service is defined
# + listeners - the list of listeners to which the service is attached  
# + resources - the list of resources in the service
public type ServiceDetail record {
    *Artifact;
    string? basePath;
    string package;
    Artifact[] listeners;
    Resource[] resources;
};

# Represents the details of a Ballerina service resource.
#
# + methods - the HTTP methods supported by the resource  
# + url - the URL of the resource
public type Resource record {
    string[] methods;
    string url;
};

# Represents the request limits for a Ballerina listener object.
#
# + maxUriLength - the maximum URI length allowed
# + maxHeaderSize - the maximum header size allowed
# + maxEntityBodySize - the maximum entity body size allowed
public type RequestLimit record {
    int maxUriLength;
    int maxHeaderSize;
    int maxEntityBodySize;
};

# Represents the details of a Ballerina listener object.
#
# + protocol - the protocol of the listener (optional)
# + package - the package where the listener is defined
public type ListenerDetail record {
    *Artifact;
    string protocol?;
    string package;
};

# Represents a Ballerina node.
#
# + platformName - the platform name (default: "ballerina")
# + platformVersion - the ballerina version (optional)
# + ballerinaHome - the ballerina home directory (optional)
# + osName - the operating system name (optional)
# + osVersion - the operating system version (optional)
public type Node record {
    string platformName = "ballerina";
    string platformVersion?;
    string ballerinaHome?;
    string osName?;
    string osVersion?;
};

# Represents a runtime registration request sent to the ICP server.
#
# + runtimeId - the unique identifier for the runtime instance
# + nodeInfo - the information about the node where the runtime is running
# + artifacts - the list of artifacts deployed in the runtime
public type RuntimeRegistrationRequest record {
    string runtimeId;
    Node nodeInfo;
    Artifacts artifacts;
};

# Represents a heartbeat message sent to the ICP server.
#
# + runtimeId - the unique identifier for the runtime instance
# + artifacts - the current list of artifacts deployed in the runtime
public type Heartbeat record {
    string runtimeId;
    Artifacts artifacts;
};