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
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.AnnotatableType;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.utils.TypeUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BListInitialValueEntry;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.PATH_SEPARATOR;

/**
 * Native function implementations of the wso2 control plane module.
 *
 * @since 1.0.0
 */
public class ListenerArtifactHandler {

    public List<BListInitialValueEntry> getListenerList(Module currentModule) {
        List<BListInitialValueEntry> artifactEntries = new ArrayList<>();
        for (Artifact artifact : ArtifactUtils.artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail("service");
            Type originalType = serviceObj.getOriginalType();
            Module module = originalType.getPackage();
            if (module != null && module.equals(currentModule)) {
                continue;
            }
            BMap<BString, Object> service = ValueCreator.createMapValue();
            service.put(StringUtils.fromString("name"), StringUtils.fromString(originalType.toString()));
            service.put(StringUtils.fromString("type"), "Service");
            service.put(StringUtils.fromString("metadata"), getServiceMetadata(artifact, serviceObj, currentModule));
            service.put(StringUtils.fromString("annotations"), getServiceAnnotations(serviceObj));
            artifactEntries.add(ValueCreator.createListInitialValueEntry(ValueCreator.createReadonlyRecordValue(currentModule, "Service", service)));
        }
        return artifactEntries;
    }

    public BMap<BString, Object> getDetailedListener(BObject listener, Module currentModule) {
//        BObject serviceObj = (BObject) artifact.getDetail("service");
//        Type originalType = serviceObj.getOriginalType();
        BMap<BString, Object> service = ValueCreator.createMapValue();
//        service.put(StringUtils.fromString("name"), StringUtils.fromString(originalType.toString()));
//        service.put(StringUtils.fromString("type"), "Service");
//        service.put(StringUtils.fromString("metadata"), getServiceMetadata(artifact, serviceObj, currentModule));
//        service.put(StringUtils.fromString("annotations"), getServiceAnnotations(serviceObj));
        return ValueCreator.createReadonlyRecordValue(currentModule, "Service", service);

    }

    private static BMap<BString, Object> getServiceMetadata(Artifact artifact, BObject serviceObj, Module module) {
        BMap<BString, Object> metadata = ValueCreator.createRecordValue(module, "Metadata");
        List<BObject> listeners = (List<BObject>) artifact.getDetail("listeners");
        BListInitialValueEntry[] listenerEntries = new BListInitialValueEntry[listeners.size()];
        for (int i = 0; i < listeners.size(); i++) {
            BObject listener = listeners.get(i);
            BMap<BString, Object> listenerRecord = ValueCreator.createMapValue();
            listenerRecord.put(StringUtils.fromString("type"), StringUtils.fromString(listener.getOriginalType().toString()));
            // Need to add listener properties according to the listener type
            BMap<BString, Object> properties = getMapAnydataValue();
            addListenerProperty(listener, "port", properties);
            listenerRecord.put(StringUtils.fromString("properties"), properties);
            listenerEntries[i] = ValueCreator.createListInitialValueEntry(ValueCreator.createReadonlyRecordValue(module, "Listener", listenerRecord));
        }
        ArrayType arrayType = TypeCreator.createArrayType(TypeUtils.getType(ValueCreator.createRecordValue(module, "Listener")), true);
        metadata.put(StringUtils.fromString("listeners"), ValueCreator.createArrayValue(arrayType, listenerEntries));
        metadata.put(StringUtils.fromString("metadata"), getMapAnydataValue());
        return metadata;
    }

    private static BMap<BString, Object> getMapAnydataValue() {
        return ValueCreator.createMapValue(TypeCreator.createMapType(PredefinedTypes.TYPE_ANYDATA));
    }

    private static Object getServiceAnnotations(BObject serviceObj) {
        BMap<BString, Object> mapValue = getMapAnydataValue();
        AnnotatableType serviceType = (AnnotatableType) TypeUtils.getImpliedType(serviceObj.getOriginalType());
        for (Map.Entry<BString, Object> entry : serviceType.getAnnotations().entrySet()) {
            mapValue.put(entry.getKey(), entry.getValue());
        }
        return mapValue;
    }

    private static void addListenerProperty(BObject listener, String fieldName, BMap<BString, Object> properties) {
        try {
            Object value = listener.get(StringUtils.fromString(fieldName));
            properties.put(StringUtils.fromString(fieldName), value);
        } catch (BError e) {
            // this means no such field in the object
        }
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
}
