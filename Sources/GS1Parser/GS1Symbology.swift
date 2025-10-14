//
//  GS1Symbology.swift
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

/// Represents the GS1 symbologies supported by a GS1 parser.
public enum GS1Symbology {
    /// GS1 DataBar Omnidirectional
    case dataBarOmni
    /// GS1 DataBar Truncated
    case dataBarTruncated
    /// GS1 DataBar Stacked
    case dataBarStacked
    /// GS1 DataBar Stacked Omnidirectional
    case dataBarStackedOmni
    /// GS1 DataBar Limited
    case dataBarLimited
    /// GS1 DataBar Expanded
    case dataBarExpanded
    /// UPC-A
    case upca
    /// UPC-E
    case upce
    /// EAN-13
    case ean13
    /// EAN-8
    case ean8
    /// GS1-128 with CC-A
    case gs1_128_ccA
    /// GS1-128 with CC-C
    case gs1_128_ccC
    /// GS1 QR Code
    case qr
    /// GS1 DataMatrix
    case dataMatrix
    /// GS1 DotCode
    case dotCode
    
    // case none = -1       // Swift equivalent is nil
    // case numsyms         // Used inside getter for a safety check, not needed here
    
    var cValue: gs1_encoder_symbologies_t {
        switch self {
            case .dataBarOmni: gs1_encoder_sDataBarOmni
            case .dataBarTruncated: gs1_encoder_sDataBarTruncated
            case .dataBarStacked: gs1_encoder_sDataBarStacked
            case .dataBarStackedOmni: gs1_encoder_sDataBarStackedOmni
            case .dataBarLimited: gs1_encoder_sDataBarLimited
            case .dataBarExpanded: gs1_encoder_sDataBarExpanded
            case .upca: gs1_encoder_sUPCA
            case .upce: gs1_encoder_sUPCE
            case .ean13: gs1_encoder_sEAN13
            case .ean8: gs1_encoder_sEAN8
            case .gs1_128_ccA: gs1_encoder_sGS1_128_CCA
            case .gs1_128_ccC: gs1_encoder_sGS1_128_CCC
            case .qr: gs1_encoder_sQR
            case .dataMatrix: gs1_encoder_sDM
            case .dotCode: gs1_encoder_sDotCode
        }
    }
    
    init?(cValue: gs1_encoder_symbologies_t) {
        switch cValue {
            case gs1_encoder_sDataBarOmni: self = .dataBarOmni
            case gs1_encoder_sDataBarTruncated: self = .dataBarTruncated
            case gs1_encoder_sDataBarStacked: self = .dataBarStacked
            case gs1_encoder_sDataBarStackedOmni: self = .dataBarStackedOmni
            case gs1_encoder_sDataBarLimited: self = .dataBarLimited
            case gs1_encoder_sDataBarExpanded: self = .dataBarExpanded
            case gs1_encoder_sUPCA: self = .upca
            case gs1_encoder_sUPCE: self = .upce
            case gs1_encoder_sEAN13: self = .ean13
            case gs1_encoder_sEAN8: self = .ean8
            case gs1_encoder_sGS1_128_CCA: self = .gs1_128_ccA
            case gs1_encoder_sGS1_128_CCC: self = .gs1_128_ccC
            case gs1_encoder_sQR: self = .qr
            case gs1_encoder_sDM: self = .dataMatrix
            case gs1_encoder_sDotCode: self = .dotCode
            default: return nil
        }
    }
}
