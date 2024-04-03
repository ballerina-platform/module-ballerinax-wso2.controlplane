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

import io.ballerina.runtime.api.Module;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;

/**
 * Native function implementations of the wso2 controlplane module.
 *
 * @since 1.0.0
 */
public class Utils {

    public static BMap<BString, Object> getArtifacts() {
        Module currentModule = new Module("ballerinai", "remote.management", "1.0.0");
        BMap<BString, Object> artifactEntries = ValueCreator.createMapValue();
        return ValueCreator.createReadonlyRecordValue(currentModule, "ArtifactsResponse", artifactEntries);
    }
}
