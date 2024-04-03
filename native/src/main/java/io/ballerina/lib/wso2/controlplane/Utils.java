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
import io.ballerina.runtime.api.Node;
import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
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
import io.ballerina.runtime.api.values.BTypedesc;

import java.util.ArrayList;
import java.util.List;

import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.BALLERINA_HOME;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.BALLERINA_VERSION;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.BAL_HOME;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.BAL_VERSION;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.ID;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.NODE_DATA;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.OS;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.OS_NAME;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.OS_VERSION;
import static io.ballerina.lib.wso2.controlplane.ControlPlaneConstants.PATH_SEPARATOR;

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
        BMap<BString, Object> metadataEntries = ValueCreator.createMapValue();
        metadataEntries.put(StringUtils.fromString(BALLERINA_VERSION),
                StringUtils.fromString((String) node.getDetail(BAL_VERSION)));
        metadataEntries.put(StringUtils.fromString(BALLERINA_HOME),
                StringUtils.fromString((String) node.getDetail(BAL_HOME)));
        metadataEntries.put(StringUtils.fromString(OS),
                StringUtils.fromString((String) node.getDetail(OS_NAME)));
        metadataEntries.put(StringUtils.fromString(OS_VERSION),
                StringUtils.fromString((String) node.getDetail(OS_VERSION)));
        BMap<BString, Object> nodeData = ValueCreator.createReadonlyRecordValue(currentModule,
                "NodeData", metadataEntries);
        nodeEntries.put(StringUtils.fromString(ID), StringUtils.fromString(node.nodeId));
        nodeEntries.put(StringUtils.fromString(NODE_DATA), nodeData);
        return ValueCreator.createReadonlyRecordValue(currentModule, "Node", nodeEntries);
    }

    public static Object getArtifacts(Environment env, BString resourceType, Object searchKey, BTypedesc typedesc) {
        Module currentModule = env.getCurrentModule();
        Type artifactType = TypeUtils.getImpliedType(typedesc.getDescribingType());
        List<Artifact> artifacts = env.getRepository().getArtifacts();
        List<BListInitialValueEntry> artifactEntries = new ArrayList<>();
        for (Artifact artifact : artifacts) {
            BObject serviceObj = (BObject) artifact.getDetail("service");
            Type originalType = serviceObj.getOriginalType();
            Module module = originalType.getPackage();
            if (module != null && module.equals(currentModule)) {
                continue;
            }
            BMap<BString, Object> service = ValueCreator.createMapValue();
            service.put(StringUtils.fromString("name"), StringUtils.fromString(originalType.toString()));
            service.put(StringUtils.fromString("attachPoint"), getAttachPointString(artifact));
            service.put(StringUtils.fromString("metadata"), getServiceMetadata(artifact, serviceObj, currentModule));
            service.put(StringUtils.fromString("annotations"), getServiceAnnotations(artifact, serviceObj,
                    artifactType));
            artifactEntries.add(ValueCreator.createListInitialValueEntry(
                    ValueCreator.createReadonlyRecordValue(currentModule, "Service", service)));
        }
        ArrayType arrayType = TypeCreator.createArrayType(artifactType, true);
        return ValueCreator.createArrayValue(arrayType, artifactEntries.toArray(BListInitialValueEntry[]::new));
    }

    private static BMap<BString, Object> getServiceMetadata(Artifact artifact, BObject serviceObj, Module module) {
        BMap<BString, Object> metadata = ValueCreator.createRecordValue(module, "Metadata");
        List<BObject> listeners = (List<BObject>) artifact.getDetail("listeners");
        BListInitialValueEntry[] listenerEntries = new BListInitialValueEntry[listeners.size()];
        for (int i = 0; i < listeners.size(); i++) {
            BObject listener = listeners.get(i);
            BMap<BString, Object> listenerRecord = ValueCreator.createMapValue();
            listenerRecord.put(StringUtils.fromString("type"), StringUtils.fromString(listener.getOriginalType()
                    .toString()));
            BMap<BString, Object> properties = getMapAnydataValue();
            addListenerProperty(listener, "port", properties);
            listenerRecord.put(StringUtils.fromString("properties"), properties);
            listenerEntries[i] = ValueCreator.createListInitialValueEntry(ValueCreator.createReadonlyRecordValue(module,
                    "Listener", listenerRecord));
        }
        ArrayType arrayType = TypeCreator.createArrayType(TypeUtils.getType(
                ValueCreator.createRecordValue(module, "Listener")), true);
        metadata.put(StringUtils.fromString("listeners"),
                ValueCreator.createArrayValue(arrayType, listenerEntries));
        metadata.put(StringUtils.fromString("metadata"), getMapAnydataValue());
        return metadata;
    }

    private static BMap<BString, Object> getMapAnydataValue() {
        return ValueCreator.createMapValue(TypeCreator.createMapType(PredefinedTypes.TYPE_ANYDATA));
    }

    private static Object getServiceAnnotations(Artifact artifact, BObject serviceObj, Type artifactType) {
        return getMapAnydataValue();
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
