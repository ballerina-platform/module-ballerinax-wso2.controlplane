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
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.NetworkObjectType;
import io.ballerina.runtime.api.types.ResourceMethodType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BListInitialValueEntry;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.lib.wso2.controlplane.ArtifactUtils.LISTENER_NAMES_MAP;
import static io.ballerina.lib.wso2.controlplane.ArtifactUtils.SERVICE_NAMES_MAP;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.PATH_SEPARATOR;

/**
 * Native function implementations of the wso2 control plane module.
 *
 * @since 1.0.0
 */
public class ServiceArtifactHandler {

    public List<BListInitialValueEntry> getServiceList(Module currentModule) {
        List<BListInitialValueEntry> artifactEntries = new ArrayList<>();
        for (Artifact artifact : ArtifactUtils.artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail("service");
            if (Utils.isControlPlaneService(serviceObj, currentModule)) {
                continue;
            }
            BMap<BString, Object> service = ValueCreator.createMapValue();
            service.put(StringUtils.fromString("name"), StringUtils.fromString(SERVICE_NAMES_MAP.get(serviceObj)));
            service.put(StringUtils.fromString("basePath"), getAttachPointString(artifact));;
            artifactEntries.add(ValueCreator.createListInitialValueEntry(
                    ValueCreator.createReadonlyRecordValue(currentModule, "Service", service)));
        }
        return artifactEntries;
    }
    public BMap<BString, Object> getDetailedService(Artifact artifact, Module currentModule) {
        BObject serviceObj = (BObject) artifact.getDetail("service");
        Type originalType = serviceObj.getOriginalType();
        BMap<BString, Object> service = ValueCreator.createMapValue();
        service.put(StringUtils.fromString("package"), StringUtils.fromString(originalType.getPackage().toString()));
        service.put(StringUtils.fromString("listeners"), getServiceListeners((List<BObject>)
                artifact.getDetail("listeners"), currentModule));
        service.put(StringUtils.fromString("resources"), getServiceResources(serviceObj, currentModule));
        return ValueCreator.createReadonlyRecordValue(currentModule, "ServiceDetail", service);
    }

    private static Object getServiceResources(BObject serviceObj, Module currentModule) {
        ResourceMethodType[] resourceMethods = ((NetworkObjectType) serviceObj.getType()).getResourceMethods();
        BListInitialValueEntry[] listenerEntries = new BListInitialValueEntry[resourceMethods.length];
        for (int i = 0; i < resourceMethods.length; i++) {
            ResourceMethodType resourceMethod = resourceMethods[i];
            BMap<BString, Object> resourceRecord = ValueCreator.createMapValue();
            resourceRecord.put(StringUtils.fromString("methods"), getAccessorArray(resourceMethod));
            resourceRecord.put(StringUtils.fromString("url"), getUrl(resourceMethod));
            listenerEntries[i] = ValueCreator.createListInitialValueEntry(
                    ValueCreator.createReadonlyRecordValue(currentModule, "Resource", resourceRecord));
        }
        ArrayType arrayType = TypeCreator.createArrayType(TypeUtils.getType(
                ValueCreator.createRecordValue(currentModule, "Resource")), true);
        return ValueCreator.createArrayValue(arrayType, listenerEntries);
    }

    private static BString getUrl(ResourceMethodType resourceMethod) {
        String[] paths = resourceMethod.getResourcePath();
        StringBuilder resourcePath = new StringBuilder();
        int count = 0;
        for (String segment : paths) {
            resourcePath.append(ControlPlaneConstants.SINGLE_SLASH);
            if (ControlPlaneConstants.PATH_PARAM_IDENTIFIER.equals(segment)) {
                String pathSegment = resourceMethod.getParamNames()[count++];
                resourcePath.append(ControlPlaneConstants.OPEN_CURL_IDENTIFIER)
                        .append(pathSegment).append(ControlPlaneConstants.CLOSE_CURL_IDENTIFIER);
            } else if (ControlPlaneConstants.PATH_REST_PARAM_IDENTIFIER.equals(segment)) {
                resourcePath.append(ControlPlaneConstants.STAR_IDENTIFIER);
            } else if (ControlPlaneConstants.DOT_IDENTIFIER.equals(segment)) {
                break;
            } else {
                resourcePath.append(segment);
            }
        }
        return StringUtils.fromString(resourcePath.toString().replaceAll(ControlPlaneConstants.REGEX,
                ControlPlaneConstants.SINGLE_SLASH));
    }

    private static BArray getAccessorArray(ResourceMethodType resourceMethod) {
       return ValueCreator.createReadonlyArrayValue(new BString[]
               {StringUtils.fromString(resourceMethod.getAccessor())});
    }

    private static Object getAttachPointString(Artifact artifact) {
        Object attachPoint = artifact.getDetail("attachPoint");
        if (TypeUtils.getType(attachPoint).getTag() == TypeTags.ARRAY_TAG) {
            BArray array = (BArray) attachPoint;
            StringBuilder attachPointStr = new StringBuilder();
            for (int i = 0; i < array.size(); i++) {
                attachPointStr.append(PATH_SEPARATOR).append(array.getBString(i).getValue());
            }
            return StringUtils.fromString(attachPointStr.toString());
        }
        return attachPoint;
    }

    private BArray getServiceListeners(List<BObject> listeners, Module module) {
        BListInitialValueEntry[] listenerEntries = new BListInitialValueEntry[listeners.size()];
        for (int i = 0; i < listeners.size(); i++) {
            BObject listener = listeners.get(i);
            BMap<BString, Object> listenerRecord = ValueCreator.createMapValue();
            listenerRecord.put(StringUtils.fromString("name"),
                    StringUtils.fromString(LISTENER_NAMES_MAP.get(listener)));
            listenerRecord.put(StringUtils.fromString("protocol"), getListenerProtocol(listener));
            listenerRecord.put(StringUtils.fromString("port"), listener.get(StringUtils.fromString("port")));
            listenerEntries[i] = ValueCreator.createListInitialValueEntry(
                    ValueCreator.createReadonlyRecordValue(module, "Listener", listenerRecord));
        }
        ArrayType arrayType = TypeCreator.createArrayType(TypeUtils.getType(
                ValueCreator.createRecordValue(module, "Listener")), true);
        return ValueCreator.createArrayValue(arrayType, listenerEntries);
    }

    private BString getListenerProtocol(BObject listener) {
        BMap<BString, Object> config = (BMap<BString, Object>)
                listener.get(StringUtils.fromString("inferredConfig"));
        Object secureSocket = config.get(StringUtils.fromString("secureSocket"));
        return StringUtils.fromString(secureSocket == null ? "HTTP" : "HTTPS");
    }

}
