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

import io.ballerina.runtime.api.Artifact;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BListInitialValueEntry;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static io.ballerina.lib.wso2.controlplane.ArtifactUtils.LISTENER_NAMES_MAP;

/**
 * Native function implementations of the wso2 control plane module.
 *
 * @since 1.0.0
 */
public class ListenerArtifactHandler {

    public List<BListInitialValueEntry> getListenerList(Module currentModule) {
        List<BListInitialValueEntry> artifactEntries = new ArrayList<>();
        Set<BObject> listeners = getNonDuplicatedListeners(ArtifactUtils.artifacts, currentModule);
        for (BObject listener : listeners) {
            artifactEntries.add(ValueCreator.createListInitialValueEntry(getServiceListener(listener, currentModule)));
        }
        return artifactEntries;
    }

    private Set<BObject> getNonDuplicatedListeners(List<Artifact> artifacts, Module currentModule) {
        Set<BObject> listeners = new HashSet<>();
        for (Artifact artifact : artifacts) {
            if (Utils.isControlPlaneService((BObject) artifact.getDetail("service"), currentModule)) {
                continue;
            }
            listeners.addAll((List<BObject>) artifact.getDetail("listeners"));
        }
        return listeners;
    }

    public BMap<BString, Object> getDetailedListener(BObject listener, Module currentModule) {
        // {
        //    "package": "testOrg/artifacts_tests:1",
        //    "httpVersion": "1.1",
        //    "host": "localhost",
        //    "timeout": "30000",
        //    "requestsLimit": {
        //        "maxUriLength": "32768",
        //        "maxHeaderSize": "8192",
        //        "maxEntityBodySize": "5242880"
        //    }
        //}
        Type originalType = listener.getOriginalType();
        BMap<BString, Object> listenerRecord = ValueCreator.createMapValue();
        listenerRecord.put(StringUtils.fromString("package"),
                StringUtils.fromString(originalType.getPackage().toString()));
        BMap<BString, Object> config = (BMap<BString, Object>)
                listener.get(StringUtils.fromString("inferredConfig"));
        listenerRecord.put(StringUtils.fromString("httpVersion"),
                StringUtils.fromString(config.get(StringUtils.fromString("httpVersion")).toString()));
        listenerRecord.put(StringUtils.fromString("host"),
                StringUtils.fromString(config.get(StringUtils.fromString("host")).toString()));
        listenerRecord.put(StringUtils.fromString("timeout"),
                config.get(StringUtils.fromString("timeout")));
        listenerRecord.put(StringUtils.fromString("requestLimit"), getRequestLimit(config, currentModule));
        return ValueCreator.createReadonlyRecordValue(currentModule, "ListenerDetail", listenerRecord);
    }

    private static BMap<BString, Object> getRequestLimit(BMap<BString, Object> config, Module module) {
        return ValueCreator.createReadonlyRecordValue(module, "RequestLimit",
                (BMap<BString, Object>) config.getMapValue(StringUtils.fromString("requestLimits")));
    }

    public static BMap<BString, Object> getServiceListener(BObject listener, Module module) {
        BMap<BString, Object> listenerRecord = ValueCreator.createMapValue();
        listenerRecord.put(StringUtils.fromString("name"), StringUtils.fromString(LISTENER_NAMES_MAP.get(listener)));
        listenerRecord.put(StringUtils.fromString("protocol"), getListenerProtocol(listener));
        listenerRecord.put(StringUtils.fromString("port"), listener.get(StringUtils.fromString("port")));
        return ValueCreator.createReadonlyRecordValue(module, "Listener", listenerRecord);
    }

    private static BString getListenerProtocol(BObject listener) {
        BMap<BString, Object> config = (BMap<BString, Object>)
                listener.get(StringUtils.fromString("inferredConfig"));
        Object secureSocket = config.get(StringUtils.fromString("secureSocket"));
        return StringUtils.fromString(secureSocket == null ? "HTTP" : "HTTPS");
    }

}
