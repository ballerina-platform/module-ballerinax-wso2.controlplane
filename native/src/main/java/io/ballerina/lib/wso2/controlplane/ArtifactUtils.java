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
import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BListInitialValueEntry;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.SERVICES_RESOURCE;

/**
 * Native function implementations of the wso2 control plane module.
 *
 * @since 1.0.0
 */
public class ArtifactUtils {

    static List<Artifact> artifacts;
    private static Module currentModule;

    private static ServiceArtifactHandler serviceArtifactHandler = new ServiceArtifactHandler();
    private static ListenerArtifactHandler listenerArtifactHandler = new ListenerArtifactHandler();

    static final Map<Object,String> serviceNamesMap = new HashMap<>();
    static final Map<Object, String> listenerNamesMap = new HashMap<>();

    private static int serviceCounter = 1;
    private static int listenerCounter = 1;

    private ArtifactUtils() {
    }

    public static Object getArtifacts(Environment env, BString resourceType, BTypedesc typedesc) {
        artifacts = env.getRepository().getArtifacts();
        currentModule = env.getCurrentModule();
        populateArtifactNamesMap();
        Type artifactType = TypeUtils.getImpliedType(typedesc.getDescribingType());
        List<BListInitialValueEntry> artifactEntries;
        if (resourceType.getValue().equals(SERVICES_RESOURCE)) {
            artifactEntries =  serviceArtifactHandler.getServiceList(currentModule);
        } else {
            artifactEntries = listenerArtifactHandler.getListenerList(currentModule);
        }
        ArrayType arrayType = TypeCreator.createArrayType(artifactType, true);
        return ValueCreator.createArrayValue(arrayType, artifactEntries.toArray(BListInitialValueEntry[]::new));
    }

    private static void populateArtifactNamesMap() {
        for (Artifact artifact : artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail("service");
            if (Utils.isControlPlaneService(serviceObj, currentModule)) {
                continue;
            }

            if (!serviceNamesMap.containsKey(serviceObj)) {
                serviceNamesMap.put(serviceObj, "service_" + serviceCounter++);
            }
            List<BObject> listeners = (List<BObject>) artifact.getDetail("listeners");
            for (BObject listener : listeners) {
                if (!listenerNamesMap.containsKey(listener)) {
                    listenerNamesMap.put(listener, "listener_" + listenerCounter++);
                }
            }
        }
    }

    public static Object getDetailedArtifact(Environment env, BString resourceType, BString name,
                                             BTypedesc typedesc) {
        String value = name.getValue();
        if (resourceType.getValue().equals(SERVICES_RESOURCE)) {
           Artifact artifact = getServiceArtifact(value);
           if (artifact == null) {
               return ErrorCreator.createError(StringUtils.fromString("No service found with the name: " + name));
           }
           return serviceArtifactHandler.getDetailedService(artifact, currentModule);

        } else {
            BObject listenerObject = getListenerArtifact(value);
            if (listenerObject == null) {
                return ErrorCreator.createError(StringUtils.fromString("No listener found with the name: " + name));
            }
            return listenerArtifactHandler.getDetailedListener(listenerObject, currentModule);
        }
    }

    private static BObject getListenerArtifact(String name) {
        for (Map.Entry<Object, String> entry : listenerNamesMap.entrySet()) {
            if (entry.getValue().equals(name)) {
                return (BObject) entry.getKey();
            }
        }
        return null;
    }

    private static Artifact getServiceArtifact(String name) {
        for (Artifact artifact : artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail("service");
            if (name.equals(serviceNamesMap.get(serviceObj))) {
                return artifact;
            }
        }
        return null;
    }
}
