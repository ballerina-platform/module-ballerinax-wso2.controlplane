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
    string serviceAccount;
    string serviceAccountPassword;
};

public type Artifacts record {
    int count;
    Artifact[] list;
};

public enum ArtifactType {
    SERVICE = "services",
    LISTENER = "listeners"
}

public type Artifact record {
    string name;
};

public type ArtifactDetail ServiceDetail|ListenerDetail;

public type ServiceDetail record {
    *Artifact;
    string? basePath;
    string package;
    Artifact[] listeners;
    Resource[] resources;
};

public type Resource record {
    string[] methods;
    string url;
};

public type RequestLimit record {
    int maxUriLength;
    int maxHeaderSize;
    int maxEntityBodySize;
};

public type ListenerDetail record {
    *Artifact;
    string? protocol;
    string package;
};

public type Node record {
    string platformName = "ballerina";
    string? platformVersion;
    string? ballerinaHome;
    string? osName;
    string? osVersion;
};
