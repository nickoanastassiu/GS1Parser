//
//  GS1ParserError.swift
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

import Foundation

/// An error that can occur during GS1 data parsing.
public enum GS1ParserError: LocalizedError {
    /// Failed to initialize the underlying parser.
    case failedToInitialize
    /// No input data was provided to the parser.
    case noData
    /// The provided data is not valid GS1 data.
    case invalidAIdata
    
    /// An internal error occurred in the underlying C library.
    case internalError(String)
    
    /// An error occurred in the linter in the underlying C library.
    case linterError(String)
    
    public var errorDescription: String? {
        switch self {
            case .failedToInitialize:
                return "Failed to initialize the parser."
            case .noData:
                return "No data provided for parsing."
            case .invalidAIdata:
                return "The provided AI data is invalid."
            case .internalError(let message):
                return message
            case .linterError(let message):
                return message
        }
    }
}
