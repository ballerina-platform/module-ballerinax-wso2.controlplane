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

package io.ballerina.lib.wso2.icp;

import io.ballerina.runtime.api.Environment;
import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.repository.Artifact;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BListInitialValueEntry;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.runtime.api.values.BTypedesc;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static io.ballerina.lib.wso2.icp.Constants.BALLERINA;
import static io.ballerina.lib.wso2.icp.Constants.LISTENER;
import static io.ballerina.lib.wso2.icp.Constants.PACKAGE_NAME;
import static io.ballerina.lib.wso2.icp.Constants.PACKAGE_ORG;
import static io.ballerina.lib.wso2.icp.Constants.PACKAGE_VERSION;
import static io.ballerina.lib.wso2.icp.Constants.SERVICE;
import static io.ballerina.lib.wso2.icp.Constants.SERVICES_RESOURCE;
import static io.ballerina.lib.wso2.icp.Constants.MAIN;

/**
 * Native function implementations of the wso2 control plane module.
 *
 * @since 1.0.0
 */
public class Artifacts {
    private static final String SERVICE_PREFIX = "service_";
    private static final String LISTENER_PREFIX = "listener_";
    static volatile List<Artifact> artifacts;
    private static Module currentModule;
    private static final Services SERVICES = new Services();
    private static final Listeners LISTENERS = new Listeners();
    static final Map<Object, String> SERVICE_NAMES_MAP = new HashMap<>();
    static final Map<Object, String> LISTENER_NAMES_MAP = new HashMap<>();
    static final Map<String, BObject> LISTENERS_MAP = new HashMap<>();
    static final Map<Object, Boolean> LISTENER_STATES_MAP = new HashMap<>();
    private static int serviceCounter = 1;
    private static int listenerCounter = 1;

    private Artifacts() {
    }

    public static Object getArtifacts(Environment env, BString resourceType, BTypedesc typedesc) {
        currentModule = env.getCurrentModule();
        artifacts = filterHttpArtifacts(env.getRepository().getArtifacts());
        populateArtifactNamesMap();
        Type artifactType = TypeUtils.getImpliedType(typedesc.getDescribingType());
        List<BListInitialValueEntry> artifactEntries;
        if (resourceType.getValue().equals(SERVICES_RESOURCE)) {
            artifactEntries = SERVICES.getServiceList(currentModule);
        } else {
            artifactEntries = LISTENERS.getListenerList(currentModule);
        }
        ArrayType arrayType = TypeCreator.createArrayType(artifactType, true);
        return ValueCreator.createArrayValue(arrayType, artifactEntries.toArray(BListInitialValueEntry[]::new));
    }

    private static List<Artifact> filterHttpArtifacts(List<Artifact> artifacts) {
        List<Artifact> httpArtifacts = new ArrayList<>();
        for (Artifact artifact : artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail(SERVICE);
            if (serviceObj == null || Utils.isicpService(serviceObj, currentModule)) {
                continue;
            }
            List<BObject> listeners = (List<BObject>) artifact.getDetail(Constants.LISTENERS);
            if (listeners == null) {
                continue;
            }
            for (BObject listener : listeners) {
                if (listener == null) {
                    continue;
                }
                Type listenerType = TypeUtils.getImpliedType(listener.getOriginalType());
                Module typePackage = listenerType.getPackage();
                if (listenerType.getName().equals(LISTENER) && typePackage.getOrg().equals(BALLERINA)
                        && typePackage.getName().equals("http")) {
                    httpArtifacts.add(artifact);
                    break;
                }
            }
        }
        return httpArtifacts;
    }

    private static void populateArtifactNamesMap() {
        for (Artifact artifact : artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail(SERVICE);
            if (serviceObj == null || Utils.isicpService(serviceObj, currentModule)) {
                continue;
            }
            if (!SERVICE_NAMES_MAP.containsKey(serviceObj)) {
                SERVICE_NAMES_MAP.put(serviceObj, SERVICE_PREFIX + serviceCounter++);
            }
            List<BObject> listeners = (List<BObject>) artifact.getDetail(Constants.LISTENERS);
            if (listeners == null) {
                continue;
            }
            for (BObject listener : listeners) {
                if (listener == null) {
                    continue;
                }
                if (!LISTENER_NAMES_MAP.containsKey(listener)) {
                    LISTENER_NAMES_MAP.put(listener, LISTENER_PREFIX + listenerCounter++);
                    LISTENER_STATES_MAP.put(listener, true); // Default to enabled
                }
            }
        }
    }

    public static Object getDetailedArtifact(Environment env, BString resourceType, BString name) {
        if (artifacts == null) {
            artifacts = filterHttpArtifacts(env.getRepository().getArtifacts());
            currentModule = env.getCurrentModule();
            populateArtifactNamesMap();
        }
        String value = name.getValue();
        if (resourceType.getValue().equals(SERVICES_RESOURCE)) {
            Artifact artifact = getServiceArtifact(value);
            if (artifact == null) {
                return ErrorCreator.createError(StringUtils.fromString("No service found with the name: " + name));
            }
            return SERVICES.getDetailedService(artifact, currentModule);
        } else {
            BObject listenerObject = getListenerArtifact(value);
            if (listenerObject == null) {
                return ErrorCreator.createError(StringUtils.fromString("No listener found with the name: " + name));
            }
            return LISTENERS.getDetailedListener(listenerObject, currentModule);
        }
    }

    private static BObject getListenerArtifact(String name) {
        for (Map.Entry<Object, String> entry : LISTENER_NAMES_MAP.entrySet()) {
            if (entry.getValue().equals(name)) {
                return (BObject) entry.getKey();
            }
        }
        return null;
    }

    private static Artifact getServiceArtifact(String name) {
        for (Artifact artifact : artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail(SERVICE);
            if (name.equals(SERVICE_NAMES_MAP.get(serviceObj))) {
                return artifact;
            }
        }
        return null;
    }

    public static Object stopListenerArtifact(Environment env, BString name) {
        BObject listenerObject = getListenerArtifact(name.getValue());
        if (listenerObject == null) {
            return false;
        }

        // Detach all services attached to this listener
        for (Artifact artifact : artifacts) {
            List<BObject> listeners = (List<BObject>) artifact.getDetail(Constants.LISTENERS);
            if (listeners == null || !listeners.contains(listenerObject)) {
                continue;
            }
            BObject serviceObj = (BObject) artifact.getDetail(SERVICE);
            if (serviceObj != null) {
                env.getRuntime().callMethod(listenerObject, "detach", null, new Object[] { serviceObj });
            }
        }

        // Stop the listener gracefully
        Object result = env.getRuntime().callMethod(listenerObject, "gracefulStop", null, new Object[] {});
        if (result == null) {
            LISTENER_STATES_MAP.put(listenerObject, false); // Mark as disabled
            return true;
        }
        return false;
    }

    public static Object startListenerArtifact(Environment env, BString name) {
        BObject listenerObject = getListenerArtifact(name.getValue());
        if (listenerObject == null) {
            return false;
        }

        // Attach all services to this listener
        for (Artifact artifact : artifacts) {
            List<BObject> listeners = (List<BObject>) artifact.getDetail(Constants.LISTENERS);
            if (listeners == null || !listeners.contains(listenerObject)) {
                continue;
            }
            BObject serviceObj = (BObject) artifact.getDetail(SERVICE);
            if (serviceObj != null) {
                Object attachPoint = artifact.getDetail(Constants.ATTACH_POINT);
                env.getRuntime().callMethod(listenerObject, "attach", null, new Object[] { serviceObj, attachPoint });
            }
        }

        // Start the listener
        Object result = env.getRuntime().callMethod(listenerObject, "start", null, new Object[] {});
        if (result == null) {
            LISTENER_STATES_MAP.put(listenerObject, true); // Mark as enabled
            return true;
        }
        return false;
    }

    public static Object getMainArtifact(Environment env) {
        List<Artifact> allArtifacts = env.getRepository().getArtifacts();
        for (Artifact artifact : allArtifacts) {
            if (artifact.type.toString().equals(MAIN)) {
                Map<String, Object> details = artifact.getAllDetails();
                BMap<BString, Object> mainDetail = ValueCreator.createMapValue();
                mainDetail.put(StringUtils.fromString(PACKAGE_ORG),
                        StringUtils.fromString((String) details.get(PACKAGE_ORG)));
                mainDetail.put(StringUtils.fromString(PACKAGE_NAME),
                        StringUtils.fromString((String) details.get(PACKAGE_NAME)));
                mainDetail.put(StringUtils.fromString(PACKAGE_VERSION),
                        StringUtils.fromString((String) details.get(PACKAGE_VERSION)));
                return ValueCreator.createReadonlyRecordValue(env.getCurrentModule(), "MainDetail", mainDetail);
            }
        }
        return ErrorCreator.createError(StringUtils.fromString("No main artifacts found"));
    }
}
