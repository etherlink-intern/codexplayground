# SwiftMarkItDown

SwiftMarkItDown is the start of a native Swift/iOS document-to-Markdown pipeline inspired by Microsoft MarkItDown. The repository is structured around a Swift Package so the same core can be embedded in an iOS app, a macOS utility, or a server-side Swift service. The repo also includes a minimal SwiftUI demo app that exercises the package on iOS.

## Current scope

The first milestone focuses on small, deterministic core converters that are safe to run fully on-device:

- `txt` and `md` passthrough with text decoding and blank-line cleanup.
- `html` to Markdown using a lightweight Foundation-based converter for common headings, inline emphasis, links, code, paragraphs, and list items.
- `csv` to GitHub-Flavored Markdown tables, including quoted fields and escaped pipes.
- `json` to nested Markdown bullets with stable key ordering.

PDF, DOCX, PPTX, and XLSX are intentionally represented in the format model but return `unsupportedFormat` until their native converter modules are built.

## Package layout

```text
Package.swift
SwiftMarkItDownApp.xcodeproj/  Xcode project for the iOS demo app
App/
  SwiftMarkItDownApp/          SwiftUI app target that imports the package
Sources/
  SwiftMarkItDown/             Core library and converter protocols
  swift-markitdown/            Minimal CLI wrapper around the library
Tests/
  SwiftMarkItDownTests/        Core conversion tests
  Fixtures/                    CLI smoke-test inputs
  Expected/                    CLI smoke-test expected Markdown
```

## Library usage

```swift
import Foundation
import SwiftMarkItDown

let input = Data("<h1>Hello</h1><p>Native Swift</p>".utf8)
let request = ConversionRequest(data: input, fileName: "example.html")
let document = try MarkItDown().convert(request)

print(document.markdown)
```

## CLI usage

```bash
swift run swift-markitdown path/to/file.html
```

## iOS demo app

Open `SwiftMarkItDownApp.xcodeproj` in Xcode, select the `SwiftMarkItDownApp` scheme, and run it on an iOS simulator. The app lets you edit sample text/HTML/CSV/JSON input and convert it to Markdown with the local `SwiftMarkItDown` package.

You can also build it from Terminal on a Mac with Xcode installed:

```bash
xcodebuild \
  -project SwiftMarkItDownApp.xcodeproj \
  -scheme SwiftMarkItDownApp \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Testing

Run the unit test suite and CLI fixture smoke tests before opening a PR:

```bash
swift test
Scripts/smoke-test.sh
```

On a Mac with Xcode installed, also build the iOS demo app:

```bash
xcodebuild \
  -project SwiftMarkItDownApp.xcodeproj \
  -scheme SwiftMarkItDownApp \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

GitHub Actions runs the same Swift package, CLI smoke-test, and iOS demo app build checks on pushes to `main`, pull requests, and manual workflow dispatches.

## Roadmap

1. Expand the text/HTML/CSV/JSON converters with richer Markdown normalization and metadata extraction.
2. Add a ZIP/OpenXML package reader as shared infrastructure for DOCX, PPTX, and XLSX.
3. Implement DOCX paragraph, heading, table, hyperlink, and image-reference extraction.
4. Add PDFKit/Vision-backed PDF text and OCR extraction for Apple platforms behind conditional compilation.
5. Layer in iOS app affordances: document picker, share extension, progress reporting, and a pluggable backend escape hatch for heavyweight conversions.
