import Foundation
import SwiftMarkItDown

let arguments = CommandLine.arguments.dropFirst()

guard let path = arguments.first else {
    FileHandle.standardError.write(Data("Usage: swift-markitdown <file>\n".utf8))
    exit(64)
}

do {
    let url = URL(fileURLWithPath: String(path))
    let document = try MarkItDown().convert(contentsOf: url)
    print(document.markdown)
} catch {
    FileHandle.standardError.write(Data("swift-markitdown: \(error.localizedDescription)\n".utf8))
    exit(1)
}
