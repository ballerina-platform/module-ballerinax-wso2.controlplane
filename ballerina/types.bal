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
    string url = "";
    int heartbeatInterval = 10;
    decimal waitTimeForServicesInSeconds = 5;
    string groupId = "";
    string nodeId = "";
    string mgtApiUrl = "";
};

public type Artifacts record {
    int count;
    Artifact[] list;
};

public type Artifact Service;

public type Service record {
    string name;
    string? attachPoint;
    Metadata metadata;
    map<anydata> annotations;
};

public type Metadata record {
    Listener[] listeners;
    map<anydata> metadata;
};

public type Listener record {
    string 'type;
    string? protocol;
    map<anydata> properties;
};

public type NodeData record {
    string? ballerinaVersion;
    string? ballerinaHome;
    string? os;
    string? osVersion;
};

public type Node record {
    string id;
    NodeData nodeData;
};
