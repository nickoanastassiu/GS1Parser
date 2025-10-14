//
//  GS1Validation.swift
//  GS1Parser
//
//  Copyright (c) 2025 Nicko Anastassiu.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import CGS1SyntaxEngine

/// Represents validation checks that can be enabled or disabled in a GS1 parser.
public enum GS1Validation: CaseIterable {
    /// Validates that the input satisfies the mandatory associations for each AI.
    ///
    /// ## Example Behavior
    /// - term **Enabled**: If AI (10) is present, one of the AIs (01), (02), (03), (8006), (8026) must also be present.
    /// - term **Disabled**: AI (10) can always be present.
    case requisiteAIs
    /// Unknown AIs will not be accepted as GS1 Digital Link URI data attributes.
    ///
    /// ## Example Behavior
    /// - term **Enabled**: AI (3249) will be rejected as a valid DL attribute.
    /// - term **Disabled**: AI (3249) will be accepted as a valid DL attribute.
    case unknownAINotDLAttr
    
    //    case mutexAIs = 0         // Locked, always enabled
    //    case repeatedAIs          // Locked, always enabled
    //    case digsegSerialKey      // Locked, always enabled
    //    case numValidations       // Used only for table initialization, adding it could lead to out of bounds access
    
    var cValue: gs1_encoder_validations_t {
        switch self {
            case .requisiteAIs: gs1_encoder_vREQUISITE_AIS
            case .unknownAINotDLAttr: gs1_encoder_vUNKNOWN_AI_NOT_DL_ATTR
        }
    }
}
