/*
 * Copyright (c) 2024, WSO2 LLC. (http://wso2.com).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.ballerina.lib.wso2.controlplane;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.Node;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.BALLERINA_HOME;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.BAL_HOME;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.BAL_VERSION;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.OS_NAME;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.OS_VERSION;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.PLATFORM_VERSION;

/**
 * Native function implementations of the wso2 control plane module.
 *
 * @since 1.0.0
 */
public class Utils {

    public static Object getBallerinaNode(Environment env) {
        Module currentModule = env.getCurrentModule();
        Node node = env.getRepository().getNode();
        BMap<BString, Object> nodeEntries = ValueCreator.createMapValue();
        nodeEntries.put(StringUtils.fromString(PLATFORM_VERSION),
                StringUtils.fromString(getBallerinaVersionString((String) node.getDetail(BAL_VERSION))));
        nodeEntries.put(StringUtils.fromString(BALLERINA_HOME),
                StringUtils.fromString((String) node.getDetail(BAL_HOME)));
        nodeEntries.put(StringUtils.fromString(ControlPlaneConstants.OS_NAME),
                StringUtils.fromString((String) node.getDetail(OS_NAME)));
        nodeEntries.put(StringUtils.fromString(OS_VERSION),
                StringUtils.fromString((String) node.getDetail(OS_VERSION)));
        return ValueCreator.createReadonlyRecordValue(currentModule, "Node", nodeEntries);
    }

    private static String getBallerinaVersionString(String detail) {
        String version = detail.split("-")[0];
        int minorVersion = Integer.parseInt(version.split("\\.")[1]);
        String updateVersionText = minorVersion > 0 ? " Update " + minorVersion : "";
        return "Ballerina " + version + " (Swan Lake Update " + updateVersionText + ")";
    }

    public static boolean isControlPlaneService(BObject serviceObj, Module currentModule) {
        Type originalType = serviceObj.getOriginalType();
        Module module = originalType.getPackage();
        return module != null && module.equals(currentModule);
    }
}
