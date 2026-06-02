# Integrating SwiftMarkItDown with an Import Button

Use this guide when an iOS, iPadOS, or macOS app wants an **Import** button that lets users pick a document or image and converts the selected input to Markdown with `SwiftMarkItDown`.

The library exposes a small synchronous API:

```swift
let request = ConversionRequest(
    data: data,
    fileName: fileName,
    contentType: contentType
)
let document = try MarkItDown().convert(request)
let markdown = document.markdown
```

Image OCR is automatic for supported image formats when the app is running on Apple platforms with Vision, CoreGraphics, and ImageIO available. On platforms without those frameworks, image formats are still recognized but conversion returns `unsupportedFormat`.

## Supported import inputs

The default converter pipeline can handle these inputs from an import button:

| Category | Extensions | Notes |
| --- | --- | --- |
| Text | `txt`, `text`, `md`, `markdown` | Decoded as text and cleaned up. |
| Web | `html`, `htm` | Converted to Markdown for common tags. |
| Data | `csv`, `json` | Converted to tables or nested bullets. |
| Images | `png`, `jpg`, `jpeg`, `heic`, `heif`, `tif`, `tiff`, `gif` | Uses Apple Vision OCR where available. |

PDF, DOCX, PPTX, and XLSX are recognized by `DocumentFormat`, but still return `unsupportedFormat` until their converter modules are implemented.

## SwiftUI document import button

For most apps, start with SwiftUI's `fileImporter`. It opens the system document picker, reads the selected file into `Data`, and hands that payload to `SwiftMarkItDown`.

```swift
import SwiftMarkItDown
import SwiftUI
import UniformTypeIdentifiers

struct ImportMarkdownButton: View {
    @State private var isImporting = false
    @State private var markdown = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("Import") {
                isImporting = true
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            ScrollView {
                Text(markdown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: SwiftMarkItDownImportTypes.allowedDocumentTypes,
            allowsMultipleSelection: false
        ) { result in
            Task {
                await importSelection(result)
            }
        }
    }

    @MainActor
    private func importSelection(_ result: Result<[URL], Error>) async {
        do {
            guard let url = try result.get().first else { return }
            let converted = try await SwiftMarkItDownImporter.convertFile(url)
            markdown = converted.markdown
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

## Import helper

Use a small helper to keep file access, content type inference, and background conversion out of the view. The security-scoped-resource calls are important for files returned by the document picker.

```swift
import Foundation
import SwiftMarkItDown
import UniformTypeIdentifiers

enum SwiftMarkItDownImporter {
    static func convertFile(_ url: URL) async throws -> MarkdownDocument {
        try await Task.detached(priority: .userInitiated) {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType

            let request = ConversionRequest(
                data: data,
                fileName: url.lastPathComponent,
                contentType: contentType
            )
            return try MarkItDown().convert(request)
        }.value
    }
}
```

## Allowed document types

Expose the formats your app wants the system picker to show. This list includes current converters plus image OCR inputs.

```swift
import UniformTypeIdentifiers

enum SwiftMarkItDownImportTypes {
    static let allowedDocumentTypes: [UTType] = [
        .plainText,
        .text,
        .utf8PlainText,
        .html,
        .commaSeparatedText,
        .json,
        .png,
        .jpeg,
        .heic,
        .tiff,
        .gif
    ]
}
```

If your app wants to display future/reserved file types in the picker, add their UTTypes and handle `ConversionError.unsupportedFormat` in the error UI.

## Photo-library import button

If your app's import action should specifically pick a photo instead of opening the document picker, use `PhotosPicker` and pass the selected image data to `SwiftMarkItDown` with an image filename or format hint.

```swift
import PhotosUI
import SwiftMarkItDown
import SwiftUI

struct PhotoOCRImportButton: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var markdown = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker("Import Photo", selection: $selectedItem, matching: .images)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }

            Text(markdown)
                .textSelection(.enabled)
        }
        .onChange(of: selectedItem) { _, item in
            Task {
                await importPhoto(item)
            }
        }
    }

    @MainActor
    private func importPhoto(_ item: PhotosPickerItem?) async {
        do {
            guard let data = try await item?.loadTransferable(type: Data.self) else { return }
            let request = ConversionRequest(
                data: data,
                fileName: "photo.jpeg",
                contentType: "image/jpeg"
            )
            let document = try await Task.detached(priority: .userInitiated) {
                try MarkItDown().convert(request)
            }.value

            markdown = document.markdown
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

## Error handling recommendations

Handle these cases in the app's import UI:

- `unsupportedFormat`: show a friendly message that the selected file type is recognized but not implemented on this platform or in this release.
- `malformedInput`: show a message that the file could not be decoded, parsed, or recognized.
- Empty OCR output: keep the import successful but tell the user that no readable text was detected.
- Large files or images: run conversion off the main actor, as shown above, and show progress or a spinner.

## Where to send the Markdown

After `MarkItDown().convert(...)` returns, use `document.markdown` wherever your app already stores imported content:

- populate an editor buffer,
- attach it to a note,
- save it to a local Markdown file,
- send it to a share sheet,
- or pass it into your app's search/indexing pipeline.
