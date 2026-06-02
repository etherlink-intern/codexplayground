# SwiftMarkItDown

SwiftMarkItDown is the start of a native Swift/iOS document-to-Markdown pipeline inspired by Microsoft MarkItDown. The repository is structured around a Swift Package so the same core can be embedded in an iOS app, a macOS utility, or a server-side Swift service. The repo also includes a minimal SwiftUI demo app that exercises the package on iOS.

## What works today

The current MVP is intentionally small and deterministic. These formats have converters in the default `MarkItDown` pipeline:

| Input family | Extensions / aliases | Content-type hints | Conversion behavior | Platform availability |
| --- | --- | --- | --- | --- |
| Plain text | `txt`, `text` | `text/plain` | Decodes text and normalizes blank lines. | All package platforms. |
| Markdown | `md`, `markdown` | `text/markdown`, `text/x-markdown` | Treats Markdown as text-like input and normalizes blank lines. | All package platforms. |
| HTML | `html`, `htm` | `text/html`, `application/xhtml+xml` | Converts common headings, inline emphasis, links, code, paragraphs, and list items; ignores document `<head>`, script, and style content. | All package platforms. |
| CSV | `csv` | `text/csv`, `application/csv` | Converts rows to GitHub-Flavored Markdown tables, including quoted fields and escaped pipes. | All package platforms. |
| JSON | `json` | `application/json`, `text/json` | Converts objects and arrays to nested Markdown bullets with stable key ordering. | All package platforms. |
| Images | `png`, `jpg`, `jpeg`, `heic`, `heif`, `tif`, `tiff`, `gif` | `image/png`, `image/jpeg`, `image/heic`, `image/heif`, `image/tiff`, `image/gif` | Uses Apple Vision OCR and returns recognized text lines as Markdown text. GIF OCR uses the decoded first image. | Apple platforms that provide Vision, CoreGraphics, and ImageIO. Other platforms recognize the formats but return `unsupportedFormat`. |

The package also includes:

- A CLI wrapper for local/manual conversion checks.
- A SwiftUI iOS demo app for editing sample input and converting it to Markdown in the simulator.

PDF, DOCX, PPTX, and XLSX are represented in the format model for future native converters, but they still return `unsupportedFormat` today.


## Planned native/FOSS converter backends

PDF, DOCX, PPTX, and XLSX are intentionally reserved in `DocumentFormat`, but they are not converter-backed yet. The planned backend direction is:

| Reserved format | Planned backend | Current status |
| --- | --- | --- |
| PDF | Apple's PDFKit, with optional Vision OCR fallback for scanned pages | Recognized, returns `unsupportedFormat`. |
| DOCX | ZIPFoundation plus targeted Office Open XML parsing | Recognized, returns `unsupportedFormat`. |
| PPTX | ZIPFoundation plus targeted Office Open XML parsing | Recognized, returns `unsupportedFormat`. |
| XLSX | CoreXLSX for workbook parsing, with its resolved transitive dependencies acknowledged too | Recognized, returns `unsupportedFormat`. |

See [Docs/NativeConverterBackends.md](Docs/NativeConverterBackends.md) for the implementation plan, integration effort, source links, and acknowledgement policy. That policy requires checking the full SwiftPM dependency graph, not just direct packages; for example, a future CoreXLSX converter must also account for transitive dependencies such as XMLCoder and ZIPFoundation.

## Repository layout

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

## App import integration

See [Docs/ImportButtonIntegration.md](Docs/ImportButtonIntegration.md) for SwiftUI `fileImporter`, `PhotosPicker`, and inbound Share Extension examples that wire an app's import surfaces into `SwiftMarkItDown`, including image OCR inputs.

## CLI usage

```bash
swift run swift-markitdown path/to/file.html
```

## Testing

Run the unit test suite and CLI fixture smoke tests before opening a PR:

```bash
swift test
Scripts/smoke-test.sh
```

GitHub Actions runs the same checks on pushes to `main`, pull requests, and manual workflow dispatches.

## License

SwiftMarkItDown is available under the [MIT License](LICENSE).

## Roadmap

1. Expand the text/HTML/CSV/JSON converters with richer Markdown normalization and metadata extraction.
2. Improve OCR layout reconstruction for headings, lists, tables, and multi-column scans.
3. Add PDFKit-backed PDF text extraction, with Vision OCR fallback for scanned pages on Apple platforms.
4. Add ZIPFoundation-backed OpenXML package infrastructure for DOCX and PPTX.
5. Add DOCX/PPTX converters on top of targeted Office Open XML parsing, then add XLSX conversion with CoreXLSX.
6. Evolve the demo into a more complete iOS MVP with document picker import, inbound Share Extension handling, share/export flows, progress reporting, and a pluggable backend escape hatch for heavyweight conversions.
