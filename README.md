# SwiftMarkItDown

SwiftMarkItDown is a native Swift document-to-Markdown pipeline inspired by Microsoft MarkItDown. The repository now contains both the reusable Swift Package conversion core and a minimal SwiftUI iOS demo app that proves the package can be embedded and run from Xcode.

## What works today

The current MVP is intentionally small and deterministic so it can run fully on-device:

- `txt` and `md` passthrough with text decoding and blank-line cleanup.
- `html` to Markdown for common headings, inline emphasis, links, code, paragraphs, and list items, with document `<head>`, script, and style content ignored.
- `csv` to GitHub-Flavored Markdown tables, including quoted fields and escaped pipes.
- `json` to nested Markdown bullets with stable key ordering.
- A CLI wrapper for local/manual conversion checks.
- A SwiftUI iOS demo app for editing sample input and converting it to Markdown in the simulator.

PDF, DOCX, PPTX, and XLSX are represented in the format model but still return `unsupportedFormat` until their native converter modules are implemented.

## Repository layout

```text
Package.swift                         Swift Package manifest
SwiftMarkItDownApp.xcodeproj/         Xcode project for the iOS demo app
App/
  SwiftMarkItDownApp/                 SwiftUI app target that imports the package
Sources/
  SwiftMarkItDown/                    Core library and converter protocols
  swift-markitdown/                   Minimal CLI wrapper around the library
Scripts/
  smoke-test.sh                       CLI fixture smoke-test runner
Tests/
  SwiftMarkItDownTests/               Core conversion tests
  Fixtures/                           CLI smoke-test inputs
  Expected/                           CLI smoke-test expected Markdown
```

## Requirements

- Swift 6.0 or newer for the package and CLI.
- Xcode 16 or newer to open/build the iOS demo app.
- iOS 16 or newer simulator/device target for the demo app.

## Run the iOS demo app in Xcode

1. Clone or pull the repo on a Mac with Xcode installed.
2. Open `SwiftMarkItDownApp.xcodeproj`.
3. Select the `SwiftMarkItDownApp` scheme.
4. Select any iOS simulator.
5. Press **Run**.
6. In the app, pick Text, HTML, CSV, or JSON, edit the sample input if desired, then tap **Convert to Markdown**.

The app target depends on the local `SwiftMarkItDown` package product, so changes in `Sources/SwiftMarkItDown/` are exercised directly by the app.

You can also verify the app from Terminal on a Mac:

```bash
xcodebuild \
  -project SwiftMarkItDownApp.xcodeproj \
  -scheme SwiftMarkItDownApp \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
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

## Testing

Run the package tests and CLI smoke tests before opening a PR:

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

GitHub Actions runs `swift test`, `Scripts/smoke-test.sh`, the iOS demo `xcodebuild`, and an XCUITest UI smoke test that launches the demo app and verifies the default HTML sample converts to Markdown on an available iPhone simulator.

## Roadmap

1. Expand the text/HTML/CSV/JSON converters with richer Markdown normalization and metadata extraction.
2. Add a ZIP/OpenXML package reader as shared infrastructure for DOCX, PPTX, and XLSX.
3. Implement DOCX paragraph, heading, table, hyperlink, and image-reference extraction.
4. Add PDFKit/Vision-backed PDF text and OCR extraction for Apple platforms behind conditional compilation.
5. Evolve the demo into a more complete iOS MVP with document picker import, share/export flows, progress reporting, and a pluggable backend escape hatch for heavyweight conversions.
