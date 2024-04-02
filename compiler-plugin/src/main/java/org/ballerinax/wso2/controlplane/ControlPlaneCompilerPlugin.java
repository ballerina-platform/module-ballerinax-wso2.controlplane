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

package org.ballerinax.wso2.controlplane;

import org.ballerinalang.compiler.plugins.AbstractCompilerPlugin;
import org.ballerinalang.model.elements.Flag;
import org.ballerinalang.model.tree.AnnotationAttachmentNode;
import org.ballerinalang.model.tree.ServiceNode;
import org.ballerinalang.util.diagnostic.DiagnosticLog;

import java.util.List;

public class ControlPlaneCompilerPlugin extends AbstractCompilerPlugin {

    @Override
    public void init(DiagnosticLog diagnosticLog) {
    }

    @Override
    public void process(ServiceNode serviceNode, List<AnnotationAttachmentNode> annotations) {
        serviceNode.addFlag(Flag.SERVICE);
    }
}
