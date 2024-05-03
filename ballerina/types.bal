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

type IntegrationPlaneConnectionRequest record {
    string product = "bal";
    string groupId;
    string nodeId;
    int interval;
    string mgtApiUrl;
    ChangeNotification changeNotification = {
        deployedArtifacts: [],
        undeployedArtifacts: [],
        stateChangedArtifacts: []
    };
};

type ChangeNotification record {
    anydata[] deployedArtifacts;
    anydata[] undeployedArtifacts;
    anydata[] stateChangedArtifacts;
};

type AccessTokenResponse record {|
    string AccessToken;
|};

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
# + count - the number of artifacts.
# + list - the list of artifacts.
public type Artifacts record {
    int count;
    Artifact[] list;
};

public enum ArtifactType {
    SERVICE = "services",
    LISTENER = "listeners"
}

# Represents a Ballerina artifact.
#
# + name - the name of the artifact.
public type Artifact record {
    string name;
};

# Represents the details of a Ballerina artifact.
public type ArtifactDetail ServiceDetail|ListenerDetail;

# Represents the details of a Ballerina service.
#
# + basePath - the base path of the service.  
# + package - the package where the service is defined.
# + listeners - the list of listeners to which the service is attached.  
# + resources - the list of resources in the service.
public type ServiceDetail record {
    *Artifact;
    string? basePath;
    string package;
    Artifact[] listeners;
    Resource[] resources;
};

# Represents the details of a Ballerina service resource.
#
# + methods - the HTTP methods supported by the resource.  
# + url - the URL of the resource.
public type Resource record {
    string[] methods;
    string url;
};

# Represents the request details of a Ballerina listener object.
#
# + maxUriLength - the maximum URI length.  
# + maxHeaderSize - the maximum header size.  
# + maxEntityBodySize - the maximum entity body size.
public type RequestLimit record {
    int maxUriLength;
    int maxHeaderSize;
    int maxEntityBodySize;
};

# Represents the details of a Ballerina listener object.
#
# + protocol - the protocol of the listener.  
# + package - the package where the listener is defined.
public type ListenerDetail record {
    *Artifact;
    string? protocol;
    string package;
};

# Represents a Ballerina node.
#
# + platformName - the platform name.  
# + platformVersion - the ballerina version.  
# + ballerinaHome - the ballerina home directory.  
# + osName - the operating system name.  
# + osVersion - the operating system version.
public type Node record {
    string platformName = "ballerina";
    string? platformVersion;
    string? ballerinaHome;
    string? osName;
    string? osVersion;
};
