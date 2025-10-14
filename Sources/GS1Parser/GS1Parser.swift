//
//  GS1Parser.swift
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
import CGS1SyntaxEngine

/// A powerful and flexible parser for GS1 data, capable of handling various formats including AI element strings, GS1 Digital Link URIs, and raw barcode data.
///
/// `GS1Parser` is the primary interface for interacting with the underlying `gs1-syntax-engine` C library. It provides a modern, safe, and idiomatic Swift API for parsing, validating, and transforming GS1 data.
///
/// ## Basic Usage
///
/// To use the parser, create an instance, set the `input` string, and call the `parse()` method. After parsing, you can access various representations of the data through the parser's properties.
///
/// ```swift
/// do {
///     var parser = try GS1Parser()
///     parser.input = "(01)12345678901231(10)ABC123"
///     try parser.parse()
///
///     print("Data String: \(parser.dataString)")
///     // Data String: ^011234567890123110ABC123
///
///     print("Digital Link URI: \(try parser.digitalLinkURI())")
///     // Digital Link URI: https://id.gs1.org/01/09501101530003/10/ABC123
///
///     print("Human Readable:\n\(parser.humanReadableInterpretation.joined(separator: "\n"))")
///     // Human Readable:
///     // (01) 09501101530003
///     // (10) ABC123
///
/// } catch {
///     print("Error parsing GS1 data: \(error.localizedDescription)")
/// }
/// ```
///
/// ## Data Flow
///
/// 1.  **Initialization**: Create a `GS1Parser` instance. This sets up the necessary context for the C library.
/// 2.  **Input**: Provide the data to be parsed to the `input` property. The parser supports multiple formats (see `input` property documentation).
/// 3.  **Parsing**: Call `parse()`. The parser automatically detects the input format and processes it. This populates the internal data structures.
/// 4.  **Output**: Access the parsed data in various formats:
///     - `aiDataString`: Bracketed element string.
///     - `dataString`: Unbracketed element string with FNC1 separators.
///     - `digitalLinkURI()`: GS1 Digital Link URI.
///     - `humanReadableInterpretation`: Formatted for display.
///     - `scanData`: Raw barcode scan data with AIM symbology identifier.
///
/// ## Configuration
///
/// The parser's behavior can be customized through various properties, such as `symbology`, `addCheckDigit`, and `validations`. These should be configured *before* calling `parse()` to affect the parsing process, or before accessing output properties that depend on them (like `scanData`).
///
/// - Note: This struct is marked as `~Copyable` to ensure that the C context pointer is managed correctly with a single owner. Each instance maintains its own state. It is not thread-safe.
@available(macOS 11.0, *)
public struct GS1Parser: ~Copyable {
    // MARK: - Lifecycle
    
    private(set) var context: OpaquePointer
    
    /// Initializes a new GS1 parser instance.
    ///
    /// - Throws: `GS1ParserError.failedToInitialize` if the underlying parser context cannot be created.
    public init() throws {
        guard let ctx = gs1_encoder_init(nil) else { throw GS1ParserError.failedToInitialize }
        self.context = ctx
    }
    
    deinit { gs1_encoder_free(context) }
    
    // MARK: - Input
    
    /// The raw input string to be parsed.
    ///
    /// ## Supported Formats
    /// - term **GS1 Digital Link URI**: `https://id.gs1.org/01/12345678901231/10/ABC123`
    /// - term **Bracketed AI element string**: `(01)12345678901231(10)ABC123`
    /// - term **Unbracketed AI element string**: `^0112345678901231^10ABC123`
    /// - term **Raw barcode scan data** (with AIM symbology identifier): `]d2011234567890123110ABC123`
    /// - term **Plain GTIN** (8, 12, 13 or 14 digits only): `12345678901231`
    ///
    /// - Note: Any '(' characters in AI element values must be escaped as '`\(`' to avoid conflating them with the start of the next AI.
    public var input: String = ""
    
    /// Parses the `input` string.
    ///
    /// The method automatically detects the format of the input data and processes it accordingly.
    ///
    /// - Throws:
    ///     - `GS1ParserError.noData` if the input string is empty.
    ///     - `GS1ParserError.invalidAIdata` if the input data is not in a recognized format or is invalid.
    ///     - `GS1ParserError.internalError` or `GS1ParserError.linterError` if an error occurs within the underlying C library during parsing.
    public func parse() throws {
        guard !input.isEmpty else { throw GS1ParserError.noData }
        
        if input.starts(with: "(") { // Bracketed AI element string
            try setAIdataString(input)
        } else if input.starts(with: "]") { // Barcode scan data with AIM symbology identifier
            // This automatically sets the symbology based on the identifier
            try setScanData(input.replacingOccurrences(of: "{GS}", with: "\u{001d}"))
        } else if input.starts(with: "^") { // Unbracketed AI element string
            try setDataString(input)
        } else if input.lowercased().starts(with: "http://") || input.lowercased().starts(with: "https://") { // GS1 Digital Link URI
            try setDataString(input)
        } else if CharacterSet(charactersIn: input).isSubset(of: CharacterSet(charactersIn: "0123456789")) { // Plain numeric data (GTIN)
            if !([8, 12, 13, 14].contains(input.count)) {
                throw GS1ParserError.invalidAIdata
            }
            
            var parity = 0
            var weight = input.count % 2 == 0 ? 3 : 1
            for d in input.dropLast() {
                parity += weight * d.wholeNumberValue!
                weight = 4 - weight
            }
            parity = (10 - parity % 10) % 10
            
            if parity != input.last!.wholeNumberValue! {
                throw GS1ParserError.invalidAIdata
            }
            
            let paddedGTIN = String(repeating: "0", count: 14 - input.count) + input
            try setDataString("^01" + paddedGTIN)
        } else {
            throw GS1ParserError.invalidAIdata
        }
    }
    
    // MARK: - Configuration Properties
    
    /// The barcode symbology used for encoding.
    ///
    /// This value can either be set explicitly or automatically determined when parsing barcode scan data.
    ///
    /// - Note: If set to `nil`, no symbology-specific processing is performed and `scanData` will return `nil`.
    public var symbology: GS1Symbology? {
        get { GS1Symbology(cValue: gs1_encoder_getSym(context)) }
        set {
            let symToSet: gs1_encoder_symbologies_t = if let newValue {
                newValue.cValue
            } else {
                gs1_encoder_sNONE
            }
        
            if !gs1_encoder_setSym(context, symToSet) {
                // Should never happen as all cases are covered
                fatalError("Failed to set symbology: \(errorMessage ?? "unknown error")" )
            }
        }
    }
    
    /// A value that determines whether a check digit should be automatically added for fixed-length symbols.
    ///
    /// ## Behavior
    /// - term `false` **(default)**: The data string must contain a valid check digit.
    /// - term `true`: The data string must **not** contain a check digit as one will be generated automatically.
    ///
    /// - Note: This option is only valid for symbologies that accept fixed-length data, specifically:
    ///
    ///    - **EAN & UPC:** `.upca`, `.upce`, `.ean13`, `.ean8`
    ///    - **GS1 DataBar:** `.dataBarOmni`, `.dataBarTruncated`, `.dataBarLimited`
    ///
    ///    If the symbology is set to anything else, this property has no effect.
    public var addCheckDigit: Bool {
        get { gs1_encoder_getAddCheckDigit(context) }
        set { gs1_encoder_setAddCheckDigit(context, newValue) }
    }
    
    /// A value that determines whether AI data titles should be included in the human-readable interpretation output.
    ///
    /// ## Behavior
    /// - term `false` **(default)**: `"(01) 09501101530003"`
    /// - term `true`: `"GTIN (01) 09501101530003"`
    public var includeDataTitlesInHRI: Bool {
        get { gs1_encoder_getIncludeDataTitlesInHRI(context) }
        set { gs1_encoder_setIncludeDataTitlesInHRI(context, newValue) }
    }
    
    /// A value that determines whether to permit AIs that are not defined in the internal AI table.
    ///
    /// ## Behavior
    /// - term `false` **(default)**: All AIs represented by the input data must be known to the library's internal AI table.
    /// - term `true`: AIs not found in the internal table will be accepted, provided they conform to the general structural rules of GS1 Application Identifiers. This is useful for supporting proprietary AIs or newer AIs not yet in the library's version.
    ///
    /// Even when `true`, the parser still validates the structure of the unknown AI. For example, an AI starting with '3' must be 4 digits long, and its data part must conform to the length and character set rules for that AI family if they are defined.
    ///
    /// - Note: This option only applies when the input data is either a **bracketed AI element string** or a **Digital Link URI**. In other formats like unbracketed element strings, it's impossible to reliably determine the length of an unknown AI versus its data.
    ///
    /// ---
    ///
    /// ## Example
    /// With `permitUnknownAIs = true`:
    /// ```
    /// (3249)123456 -> Success (Assumes AI '3249' is unknown but structurally valid)
    /// (3249)1234567 -> Failure (AIs starting with '324' have a data length of 6, so 7 digits is an error)
    /// (3249)ABCDEF -> Failure (AIs starting with '324' are numeric, so 'ABCDEF' is an error)
    ///
    /// (999)1 -> Failure (AIs starting with '9' are defined as 2 digits long, e.g., '90'-'99')
    /// ```
    ///
    /// ---
    ///
    /// ## Implementation Details
    /// When an AI is not found in the main table, the library attempts to "vivify" it by checking its prefix against known GS1 rules. The GS1 standard defines length and format rules for families of AIs based on their starting digits. For instance, AIs beginning with '2' are variable length, while many starting with '3' have a fixed length. The library uses these structural rules to create a temporary definition for the unknown AI. If the AI and its data violate these structural rules, parsing will fail even if `permitUnknownAIs` is enabled.
    public var permitUnknownAIs: Bool {
        get { gs1_encoder_getPermitUnknownAIs(context) }
        set { gs1_encoder_setPermitUnknownAIs(context, newValue) }
    }

    /// A value that determines whether to permit zero-suppressed GTINs in GS1 Digital Link URIs.
    ///
    /// ## Behavior
    /// - term `false` **(default)**: The value of a path component for AI (01) must be provided as a full GTIN-14.
    /// - term `true`: The value of a path component for AI (01) may contain the GTIN-14 with zeros suppressed, in the format of a GTIN-13, GTIN-12 or GTIN-8.
    ///
    /// - Note: This option only applies when the input data is a **GS1 Digital Link URI**.
    /// - Note: Since **zero-suppressed GTINs are deprecated**, this option should only be enabled when it is necessary to accept legacy GS1 Digital Link URIs having zero-suppressed GTIN-14.
    public var permitZeroSuppressedGTINinDLuris: Bool {
        get { gs1_encoder_getPermitZeroSuppressedGTINinDLuris(context) }
        set { gs1_encoder_setPermitZeroSuppressedGTINinDLuris(context, newValue) }
    }
    
    /// The set of active validation checks.
    ///
    /// By default, all validations are enabled.
    public var validations: [GS1Validation] {
        get { GS1Validation.allCases.filter { isValidationEnabled($0) } }
        set {
            // Disable all validations first
            for validation in GS1Validation.allCases {
                toggleValidation(validation, enabled: false)
            }
            // Enable the specified validations
            for validation in newValue {
                toggleValidation(validation, enabled: true)
            }
        }
    }
    
    // MARK: - Output Properties
    
    /// The GS1 data string in unbracketed AI element string format
    ///
    /// ## Example
    /// ```
    /// ^0112345678901231^10ABC123^11210630
    /// ```
    ///
    /// ---
    /// ## Discussion
    ///
    /// A '^' character at the start of the input indicates that the data is in GS1
    /// Application Identifier syntax. In this case, all subsequent instances of the
    /// '^' character represent the FNC1 non-data characters that are used to
    /// separate fields that are not specified as being pre-defined length from
    /// subsequent fields.
    ///
    /// ## Composite Component
    ///
    /// EAN/UPC, GS1 DataBar and GS1-128 support a Composite Component. The
    /// Composite Component must be specified in AI syntax. It must be separated
    /// from the primary linear components with a '|' character and begin with an
    /// FNC1 in first position.
    ///
    /// For example:
    /// ```
    /// ^0112345678901231|^10ABC123^11210630
    /// ```
    ///
    /// This buffer specifies a linear component representing `(01)12345678901231`
    /// together with a composite component representing `(10)ABC123(11)210630`.
    public var dataString: String { String(cString: gs1_encoder_getDataStr(context)) }
    
    /// The barcode input data in human-friendly bracketed syntax without FNC1 characters.
    ///
    /// ## Example
    /// ```
    /// (01)12312312312333(10)ABC123|(99)XYZ\(TM) CORP
    /// ```
    /// Which is equivalent to the unbracketed AI element string:
    /// ```
    /// ^011231231231233310ABC123|^99XYZ(TM) CORP
    /// ```
    ///
    /// - Note: This property returns `nil` if the input data is not GS1-compliant.
    public var aiDataString: String? {
        guard let cString = gs1_encoder_getAIdataStr(context) else { return nil }
        return String(cString: cString)
    }
    
    /// The human-readable interpretation of the GS1 data, with each element as a separate string in the array.
    ///
    /// ## Example
    /// ```
    /// (01) 12312312312333
    /// (10) ABC123
    /// (99) XYZ(TM) CORP
    /// ```
    /// Which is the HRI for the unbracketed AI element string:
    /// ```
    /// ^011231231231233310ABC123|^99XYZ(TM) CORP
    /// ```
    ///
    /// ---
    /// ## Discussion
    ///
    /// If `includeDataTitlesInHRI` is set to `true`, the output would be:
    /// ```
    /// GTIN (01) 12312312312333
    /// BATCH/LOT (10) ABC123
    /// INTERNAL (99) XYZ(TM) CORP
    /// ```
    public var humanReadableInterpretation: [String] { stringArray(from: gs1_encoder_getHRI) }
    
    /// The raw barcode scan data, including the AIM symbology identifier.
    ///
    /// ## Example
    /// ```
    /// ]d2011231231231233310ABC123
    /// ```
    ///
    /// - Note: The `symbology` property must be set to a specific symbology (not `nil`), otherwise this property will return `nil`.
    ///
    /// ---
    ///
    /// ## More Examples
    ///
    /// Symbology           | Input data                                                                                         | Returned scan data
    /// ----------------- | --------------------------------------------------------------- | -------------------------------------------------
    /// EAN-13                 | `2112345678900`                                                                          | `]E02112345678900`
    /// UPC-A                  | `416000336108`                                                                            | `]E00416000336108`
    /// EAN-8                  | `02345673`                                                                                     | `]E402345673`
    /// EAN-8                  | `02345673\|^99COMPOSITE^98XYZ`                                         | `]E402345673\|]e099COMPOSITE{GS}98XYZ`
    /// GS1-128 (CC-A)  | `^011231231231233310ABC123^99TESTING`                         | `]C1011231231231233310ABC123{GS}99TESTING`
    /// GS1-128 (CC-A)  | `^0112312312312333\|^98COMPOSITE^97XYZ`                     | `]e00112312312312333{GS}98COMPOSITE{GS}97XYZ`
    /// QR Code              | `https://example.org/01/12312312312333`                     | `]Q1https://example.org/01/12312312312333`
    /// QR Code              | `^01123123123123338200http://example.com`                 | `]Q301123123123123338200http://example.com`
    /// Data Matrix          | `https://example.com/gtin/09506000134352/lot/A1` | `]d1https://example.com/gtin/09506000134352/lot/A1`
    /// Data Matrix          | `^011231231231233310ABC123^99TESTING`                         | `]d2011231231231233310ABC123{GS}99TESTING`
    /// DotCode              | `https://example.com/gtin/09506000134352/lot/A1` | `]J0https://example.com/gtin/09506000134352/lot/A1`
    /// DotCode              | `^011231231231233310ABC123^99TESTING`                         | `]J1011231231231233310ABC123{GS}99TESTING`
    ///
    /// `{GS}` in the scan data output in the above table represents a literal GS
    /// character (ASCII 29) that is included in the returned data.
    ///
    /// The literal '|' character included in the scan data output for EAN/UPC
    /// Composite symbols indicates the separation between the first and second
    /// messages that would be transmitted by a reader that is configured to return
    /// the composite component.
    public var scanData: String? {
        // Technically gs1_encoder_getScanData() can throw errors (which would return nil here),
        // so a better approach might be to make this a throwing function. However, for simplicity
        // and consistency with other properties, it is kept as a `String?`.
        guard let cString = gs1_encoder_getScanData(context) else { return nil }
        return String(cString: cString)
    }
    
    /// Generates a Digital Link URI from the parsed data.
    ///
    /// ## Example
    /// ```swift
    /// let parser = try GS1Parser()
    /// parser.input = "(01)12345678901231(10)ABC123"
    /// try parser.parse()
    ///
    /// let uri = try parser.digitalLinkURI()
    /// // Returns: https://id.gs1.org/01/12345678901231/10/ABC123
    ///
    /// let customURI = try parser.digitalLinkURI(customDomain: "https://example.com")
    /// // Returns: https://example.com/01/12345678901231/10/ABC123
    /// ```
    ///
    /// - Parameter customDomain: An optional custom domain to use for the URI (e.g., `https://example.com`). If `nil`, the default domain is used (`https://id.gs1.org`) .
    /// - Returns: A Digital Link URI string.
    /// - Throws: `GS1ParserError` if the URI cannot be generated.
    public func digitalLinkURI(customDomain: String? = nil) throws -> String {
        let cString: UnsafeMutablePointer<CChar>?
        if let customDomain {
            cString = customDomain.withCString { domainPtr in
                gs1_encoder_getDLuri(context, UnsafeMutablePointer(mutating: domainPtr))
            }
        } else {
            cString = gs1_encoder_getDLuri(context, nil)
        }
        
        guard let cString else {
            if let errorMessage {
                throw GS1ParserError.internalError(errorMessage)
            } else if let linterErrorMessage {
                throw GS1ParserError.linterError(linterErrorMessage)
            } else {
                throw GS1ParserError.internalError("An unknown error occurred.")
            }
        }
        return String(cString: cString)
    }
    
    /// The query parameters that were present in the input Digital Link URI but were ignored during parsing.
    ///
    /// ## Example
    /// If the input URI is:
    /// ```
    /// https://a/01/12312312312333/22/ABC?name=Donald%2dDuck&99=ABC&testing&type=cartoon
    /// ```
    /// Then this property would return:
    /// ```
    /// ["name=Donald%2dDuck", "testing", "type=cartoon"]
    /// ```
    public var digitalLinkIgnoredQueryParams: [String] { stringArray(from: gs1_encoder_getDLignoredQueryParams) }
    
    // MARK: - Private Helpers
    
    // MARK: Error Handling
    
    // Currently (13 Oct 2025), the errors API is internal and we only
    // have access to the error message strings. If more detailed error
    // handling is exposed in future versions, these properties will be
    // deprecated in favor of a more structured error handling approach.
    
    private var errorMessage: String? {
        guard let cString = gs1_encoder_getErrMsg(context) else { return nil }
        return String(cString: cString)
    }
    
    private var linterErrorMessage: String? {
        guard let cString = gs1_encoder_getErrMarkup(context) else { return nil }
        return String(cString: cString)
    }
    
    // MARK: Configuration Helpers
    
    private func isValidationEnabled(_ validation: GS1Validation) -> Bool {
        return gs1_encoder_getValidationEnabled(context, validation.cValue)
    }
    
    private func toggleValidation(_ validation: GS1Validation, enabled: Bool) {
        if !gs1_encoder_setValidationEnabled(context, validation.cValue, enabled) {
            // Should never happen as all cases are covered
            fatalError("Failed to \(enabled ? "enable" : "disable") validation: \(errorMessage ?? "unknown error")" )
        }
    }
    
    // MARK: Input Setters
    
    private func setDataString(_ data: String) throws {
        let success = data.withCString { cString in
            gs1_encoder_setDataStr(context, UnsafeMutablePointer(mutating: cString))
        }
        guard success else {
            if let errorMessage {
                throw GS1ParserError.internalError(errorMessage)
            } else if let linterErrorMessage {
                throw GS1ParserError.linterError(linterErrorMessage)
            } else {
                throw GS1ParserError.internalError("An unknown error occurred.")
            }
        }
    }
    
    private func setAIdataString(_ aiData: String) throws {
        let success = aiData.withCString { cString in
            gs1_encoder_setAIdataStr(context, UnsafeMutablePointer(mutating: cString))
        }
        guard success else {
            if let errorMessage {
                throw GS1ParserError.internalError(errorMessage)
            } else if let linterErrorMessage {
                throw GS1ParserError.linterError(linterErrorMessage)
            } else {
                throw GS1ParserError.internalError("An unknown error occurred.")
            }
        }
    }
    
    private func setScanData(_ scanData: String) throws {
        let success = scanData.withCString { cString in
            gs1_encoder_setScanData(context, UnsafeMutablePointer(mutating: cString))
        }
        guard success else {
            if let errorMessage {
                throw GS1ParserError.internalError(errorMessage)
            } else if let linterErrorMessage {
                throw GS1ParserError.linterError(linterErrorMessage)
            } else {
                throw GS1ParserError.internalError("An unknown error occurred.")
            }
        }
    }
    
    // MARK: Output Helpers

    private func stringArray(from cFunction: (OpaquePointer?, UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?>?) -> Int32) -> [String] {
        let pointer = UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?>.allocate(capacity: 1)
        defer {
            pointer.deinitialize(count: 1)
            pointer.deallocate()
        }
        
        let count = Int(cFunction(context, pointer))
        guard count > 0, let elements = pointer.pointee else { return [] }
        
        return UnsafeBufferPointer(start: elements, count: count).compactMap { $0 }.map { String(cString: $0) }
    }
}
