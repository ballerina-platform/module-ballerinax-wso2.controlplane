# module-ballerinax-wso2.controlplane

[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-wso2.controlplane.svg)](https://github.com/ballerina-platform/module-wso2.controlplane/commits/main)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![codecov](https://codecov.io/gh/ballerina-platform/module-ballerinax-wso2.controlplane/branch/main/graph/badge.svg?token=5GCQ36HBEB)](https://codecov.io/gh/ballerina-platform/module-ballerinax-wso2.controlplane)

This repository is for adding Ballerina support with WSO2 Integration Control Plane.

## Adding control plane support to a Ballerina project with services

1. Add `import ballerinax/wso2.controlplane as _;` to the default module.
2. Add `remoteManagement=true` to `[build-options]` section of the Ballerina.toml file.
3. Create Config.toml file if it does not exist, and add the following configurations.
    ```toml
    [ballerinax.wso2.controlplane]
    # keyStorePath = "../keystore.p12"
    # trustStorePath = "../truststore.p12"
    # icpServicePort = 9264

    [ballerinax.wso2.controlplane.dashboard]
    url = "https://localhost:9743/dashboard/api"
    heartbeatInterval = 10
    groupId = "cluster1"
    mgtApiUrl ="https://localhost:9264/management/"
    # nodeId = "node1"
    # serviceAccount = "bal_admin"
    # serviceAccountPassword = "bal_secret"
    ```
    Modify the configurations to match your integration control plane dashboard.

    If there are multiple nodes in the same machine, make sure to pick a unique icpServicePort (same in mgtApiUrl) for each node.

## Building from the Source

### Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 17 (from one of the following locations).

    * [Oracle](https://www.oracle.com/java/technologies/downloads/)

    * [OpenJDK](https://adoptopenjdk.net/)

      > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.

### Building the Source

Execute the commands below to build from source.

1. To build the library:

        ./gradlew clean build

2. To run the integration tests:

        ./gradlew clean test

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss about code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
* View the [Ballerina performance test results](https://github.com/ballerina-platform/ballerina-lang/blob/master/performance/benchmarks/summary.md).
