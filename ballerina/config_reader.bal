import ballerina/file;
import ballerina/os;
import ballerina/uuid;

configurable string serverUrl = "http://localhost:9264";
configurable string authToken = "";
configurable decimal heartbeatInterval = 5.0;
configurable string opensearchURL = "";
configurable string logIndex = "icp-logs";
configurable boolean metricsEnabled = false;

// configurable DashBoard dashboard = ?;
configurable string keyStorePath = check getDefaultKeyStore();
configurable string keyStorePassword = "ballerina";
configurable string trustStorePath = check getDefaultTrustStore();
configurable string trustStorePassword = "ballerina";

configurable string runtimeId = uuid:createRandomUuid();

function getDefaultTrustStore() returns string|error {
    string trustStorePath = check file:joinPath(os:getEnv("BALLERINA_HOME"), "bre", "security", "ballerinaTruststore.p12");
    return trustStorePath;
}

configurable int icpServicePort = 9264;

function getDefaultKeyStore() returns string|error {
    string keyStorePath = check file:joinPath(os:getEnv("BALLERINA_HOME"), "bre", "security", "ballerinaKeystore.p12");
    return keyStorePath;
}

public function loadConfig() returns IcpConfig|error {
    IcpConfig config = {
        icp: {
            serverUrl: serverUrl,
            authToken: authToken,
            heartbeatInterval: heartbeatInterval
        },
        observability: {
            opensearchUrl: opensearchURL,
            logIndex: logIndex,
            metricsEnabled: metricsEnabled
        }
    };
    return config;
}
