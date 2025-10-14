# GS1Parser

A modern, lightweight, and efficient Swift library for parsing and handling GS1 data. This package provides a wrapper around the official C [GS1 Syntax Engine](https://github.com/gs1/gs1-syntax-engine).

## Features

- **Versatile Parsing**: Handles multiple GS1 data formats out-of-the-box:
	- **Bracketed AI element string:** `(01)03453120000011(10)ABC123`
	- **Barcode scan data with an AIM symbology identifier:** `]d2010345312000001110ABC123`
	- **Unbracketed AI element string (starting with `^`):** `^010345312000001110ABC123`
	- **GS1 Digital Link URI:** `https://id.gs1.org/01/03453120000011/10/ABC123`
- **Digital Link URI Generation**: Effortlessly create GS1 Digital Link URIs from parsed data, with support for custom domains.
- **Barcode Message Generation**: Produces a data string which can be used for barcode generation.
- **Human-Readable Interpretation (HRI)**: Provides the HRI text for displaying below a barcode.
- **Lightweight & Performant**: A thin wrapper around a highly-optimized C engine with no external dependencies.
- **Type Safe**: Modern Swift API with clear error handling.

## Installation

You can add `GS1Parser` to your project using the Swift Package Manager. Add it as a dependency in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/nickoanastassiu/GS1Parser.git", from: "0.1.0")
]
```

Or, add it to your Xcode project by going to **File > Add Packages...** and entering the repository URL.

## Quick Start

Parsing GS1 data is simple. Just import `GS1Parser` and initialize the `GS1Parser` struct with your data string.

```swift
import GS1Parser

do {
    var parser = try GS1Parser()
    
    // Parse the input data
    parser.input = "(01)03453120000011(10)ABC123"
    try parser.parse()

    // Get the GS1 Digital Link URI
    print(try parser.digitalLinkURI())
    // -> https://id.gs1.org/01/03453120000011/10/ABC123

    // Get the human-readable interpretation
    print(parser.humanReadableInterpretation)
    // -> ["(01) 03453120000011", "(10) ABC123"]

    // Get the raw message for barcode encoding
    print(parser.dataString)
    // -> "^010345312000001110ABC123"

} catch {
    print("Failed to parse GS1 data: \(error)")
}
```

## Usage Examples

### Parsing a Plain GTIN

`GS1Parser` automatically validates the check digit and formats the GTIN.

```swift
var parser = try GS1Parser()
parser.input = "9501101530003" // 13-digit GTIN
parser.parse()

print(parser.dataString)
// -> ^0100950110153003
```

### Parsing a GS1 Digital Link URI

```swift
var parser = try GS1Parser()
parser.input = "https://example.com/01/09501101530003/10/ABC"
parser.parse()

print(parser.aiDataString ?? "N/A")
// -> (01)09501101530003(10)ABC
```

### Generating a Digital Link with a Custom Domain

```swift
var parser = try GS1Parser()
parser.input = "(01)09501101530003"
try parser.parse()

let customURI = try parser.digitalLinkURI(customDomain: "https://my.domain.com")
print(customURI)
// -> https://my.domain.com/01/09501101530003
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project and the original C library are licensed under the Apache-2.0 License. See the LICENSE file for details.
