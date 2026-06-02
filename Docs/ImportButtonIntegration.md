# Integrating SwiftMarkItDown with Import Buttons and Share Sheet Imports

Use this guide when an iOS, iPadOS, or macOS app wants to accept user-selected documents or images and convert them to Markdown with `SwiftMarkItDown`. The same conversion core works for:

- an in-app **Import** button backed by the system document picker,
- photo-library OCR imports,
- inbound iOS/iPadOS Share Sheet actions through a Share Extension,
- and drag/drop or other app-specific import surfaces that can produce `Data` plus filename or content-type hints.

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

The default converter pipeline can handle these inputs from an import button or Share Extension:

| Category | Extensions | MIME / UTType examples | Notes |
| --- | --- | --- | --- |
| Plain text | `txt`, `text` | `text/plain`, `.plainText`, `.text`, `.utf8PlainText` | Decoded as text and cleaned up. |
| Markdown | `md`, `markdown` | `text/markdown`, `text/x-markdown` | Treated as text-like input and cleaned up. |
| HTML | `html`, `htm` | `text/html`, `application/xhtml+xml`, `.html` | Converted to Markdown for common tags. |
| CSV | `csv` | `text/csv`, `application/csv`, `.commaSeparatedText` | Converted to GitHub-Flavored Markdown tables. |
| JSON | `json` | `application/json`, `text/json`, `.json` | Converted to nested Markdown bullets. |
| Images | `png`, `jpg`, `jpeg`, `heic`, `heif`, `tif`, `tiff`, `gif` | `image/png`, `image/jpeg`, `image/heic`, `image/heif`, `image/tiff`, `image/gif`, `.image` | Uses Apple Vision OCR where available. GIF inputs are decoded as an image source; OCR is performed on the decoded first image. |

PDF, DOCX, PPTX, and XLSX are recognized by `DocumentFormat`, but still return `unsupportedFormat` until their converter modules are implemented.

## Reusable conversion helper

Use a small helper to keep file access, content type inference, and background conversion out of your SwiftUI views and Share Extension controllers.

```swift
import Foundation
import SwiftMarkItDown
import UniformTypeIdentifiers

enum SwiftMarkItDownImporter {
    static func convertData(
        _ data: Data,
        fileName: String? = nil,
        contentType: String? = nil,
        formatHint: DocumentFormat? = nil
    ) async throws -> MarkdownDocument {
        let request = ConversionRequest(
            data: data,
            fileName: fileName,
            contentType: contentType,
            formatHint: formatHint
        )

        return try await Task.detached(priority: .userInitiated) {
            try MarkItDown().convert(request)
        }.value
    }

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

The security-scoped-resource calls are important for URLs returned by the document picker and for some URLs delivered by extensions.

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
            let document = try await SwiftMarkItDownImporter.convertData(
                data,
                fileName: "photo.jpeg",
                contentType: "image/jpeg"
            )

            markdown = document.markdown
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

## Inbound Share Sheet import

To let users send documents or images into your app from Files, Photos, Mail, Safari, or another app's Share Sheet, add an iOS/iPadOS **Share Extension** target to the consuming app. The extension receives one or more `NSItemProvider` attachments, loads supported file or data representations, converts each attachment with `SwiftMarkItDown`, then stores or forwards the Markdown to the containing app. Link the Share Extension target against `SwiftMarkItDown` the same way you link the main app target, and use an app group if the extension needs to hand converted Markdown back to the containing app.

A typical Share Extension flow is:

1. Configure the extension activation rule for text, web content, files, and images.
2. Iterate through `extensionContext.inputItems`.
3. Prefer `loadFileRepresentation(forTypeIdentifier:)` for document-like attachments so you can preserve filenames and file extensions.
4. Fall back to `loadDataRepresentation(forTypeIdentifier:)` for in-memory text/image payloads.
5. Convert each payload off the main actor.
6. Save the Markdown to an app-group container, post it to your app backend, or open the containing app with a URL scheme/deep link.

### Share Extension activation rule

In the Share Extension target's `Info.plist`, allow the same categories that `SwiftMarkItDown` can convert today. Keep the rule as narrow as your product needs.

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsText</key>
            <true/>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsWebPageWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsFileWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>10</integer>
        </dict>
    </dict>
</dict>
```

### Share Extension conversion example

The exact UI is up to the host app, but the import core can be isolated in a coordinator like this:

```swift
import Foundation
import SwiftMarkItDown
import UniformTypeIdentifiers

final class ShareSheetImportCoordinator {
    private let supportedTypes: [UTType] = [
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
        .gif,
        .image,
        .fileURL
    ]

    func convertSharedItems(from extensionContext: NSExtensionContext) async -> [Result<MarkdownDocument, Error>] {
        let providers = extensionContext.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .flatMap { $0.attachments ?? [] }

        return await withTaskGroup(of: Result<MarkdownDocument, Error>.self) { group in
            for provider in providers {
                group.addTask {
                    do {
                        return .success(try await self.convert(provider))
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var results: [Result<MarkdownDocument, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    private func convert(_ provider: NSItemProvider) async throws -> MarkdownDocument {
        guard let type = supportedTypes.first(where: { provider.hasItemConformingToTypeIdentifier($0.identifier) }) else {
            throw ConversionError.unsupportedFormat(.unknown)
        }

        if type == .fileURL {
            let url = try await provider.loadURL(typeIdentifier: type.identifier)
            return try await SwiftMarkItDownImporter.convertFile(url)
        }

        if let url = try? await provider.loadFile(typeIdentifier: type.identifier) {
            return try await SwiftMarkItDownImporter.convertFile(url)
        }

        let data = try await provider.loadData(typeIdentifier: type.identifier)
        return try await SwiftMarkItDownImporter.convertData(
            data,
            fileName: suggestedFileName(for: provider, type: type),
            contentType: type.preferredMIMEType
        )
    }

    private func suggestedFileName(for provider: NSItemProvider, type: UTType) -> String? {
        guard let extensionName = type.preferredFilenameExtension else {
            return provider.suggestedName
        }

        let baseName = provider.suggestedName ?? "shared-item"
        if baseName.lowercased().hasSuffix(".\(extensionName.lowercased())") {
            return baseName
        }
        return "\(baseName).\(extensionName)"
    }
}

private extension NSItemProvider {
    func loadURL(typeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ConversionError.malformedInput("The shared file URL could not be loaded."))
                }
            }
        }
    }

    func loadFile(typeIdentifier: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadFileRepresentation(forTypeIdentifier: typeIdentifier) { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ConversionError.malformedInput("The shared file could not be loaded."))
                }
            }
        }
    }

    func loadData(typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: ConversionError.malformedInput("The shared data could not be loaded."))
                }
            }
        }
    }
}
```

`loadFileRepresentation` can hand your extension a temporary file URL. If you need the original data after the completion handler returns, copy that file into your extension's temporary directory or an app-group container before returning from the callback.

## Error handling recommendations

Handle these cases in the app's import UI or Share Extension UI:

- `unsupportedFormat`: show a friendly message that the selected file type is recognized but not implemented on this platform or in this release.
- `malformedInput`: show a message that the file could not be decoded, parsed, or recognized.
- Empty OCR output: keep the import successful but tell the user that no readable text was detected.
- Large files or images: run conversion off the main actor, as shown above, and show progress or a spinner.
- Multiple shared attachments: convert each attachment independently, and present partial successes instead of failing the entire share operation.

## Where to send the Markdown

After `MarkItDown().convert(...)` returns, use `document.markdown` wherever your app already stores imported content:

- populate an editor buffer,
- attach it to a note,
- save it to a local Markdown file,
- write it into an app-group container for the containing app,
- open the containing app with a deep link that references the converted item,
- send it to a share sheet,
- or pass it into your app's search/indexing pipeline.
