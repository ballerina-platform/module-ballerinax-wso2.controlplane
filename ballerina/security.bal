import ballerina/jwt;

jwt:IssuerConfig issuerConfig = {
    issuer: "https://localhost:9164/",
    username: "admin",
    customClaims: {
        iss: "https://localhost:9164/",
        sub: "admin",
        exp: 1715452200000,
        scope: "admin"
    }
};
final string jwt = check jwt:issue(issuerConfig);
