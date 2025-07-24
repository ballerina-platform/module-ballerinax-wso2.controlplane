import ballerina/http;
import ballerina/log;

public client class IcpClient {
    private final http:Client httpClient;
    private final IcpConfig config;

    public function init(IcpConfig config) returns http:ClientError? {
        self.config = config;
        self.httpClient = check new (config.icp.serverUrl);
    }

    // Register runtime with ICP server
    isolated remote function registerRuntime(RuntimeRegistrationRequest runtimeRegistration) returns error? {

        http:Request request = new;
        request.setHeader("Authorization", self.config.icp.authToken);
        request.setPayload(runtimeRegistration);
        log:printInfo("Registering runtime with ICP server: " + runtimeRegistration.toJsonString());
        // http:Response response = check self.httpClient->post("/register", request);
        // if response.statusCode != http:STATUS_CREATED {
        //     log:printError("Failed to register runtime with ICP server");
        //     return error("Registration failed ");
        // }
    }

    // Send heartbeat to ICP server
    isolated remote function sendHeartbeat(Heartbeat heartbeat) returns error? {
        http:Request request = new;
        request.setHeader("Authorization", self.config.icp.authToken);
        request.setPayload(heartbeat);
        log:printInfo("Sending heartbeat to ICP server: " + heartbeat.toJsonString());

        // http:Response response = check self.httpClient->post("/heartbeat", request);
        // if response.statusCode != http:STATUS_OK {
        // log:printWarn("Heartbeat failed: " + response.statusCode.toString());
        // return error("Heartbeat failed");
        // }
    }

}
