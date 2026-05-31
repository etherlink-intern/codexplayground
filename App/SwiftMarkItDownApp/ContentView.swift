import Foundation
import SwiftMarkItDown
import SwiftUI

struct ContentView: View {
    @State private var selectedFormat = DemoFormat.html
    @State private var input = DemoFormat.html.sampleInput
    @State private var output = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Input") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(DemoFormat.allCases) { format in
                            Text(format.label).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedFormat) { newValue in
                        input = newValue.sampleInput
                        output = ""
                        errorMessage = nil
                    }

                    TextEditor(text: $input)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 180)
                        .accessibilityIdentifier("conversionInput")
                }

                Section {
                    Button("Convert to Markdown", action: convert)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("convertButton")
                }

                if let errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Markdown Output") {
                    TextEditor(text: .constant(output))
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 180)
                        .accessibilityIdentifier("conversionOutput")
                }
            }
            .navigationTitle("SwiftMarkItDown")
        }
    }

    private func convert() {
        do {
            let request = ConversionRequest(
                data: Data(input.utf8),
                fileName: "sample.\(selectedFormat.fileExtension)",
                formatHint: selectedFormat.documentFormat
            )
            output = try MarkItDown().convert(request).markdown
            errorMessage = nil
        } catch {
            output = ""
            errorMessage = error.localizedDescription
        }
    }
}

private enum DemoFormat: String, CaseIterable, Identifiable {
    case plainText
    case html
    case csv
    case json

    var id: String { rawValue }

    var label: String {
        switch self {
        case .plainText: "Text"
        case .html: "HTML"
        case .csv: "CSV"
        case .json: "JSON"
        }
    }

    var fileExtension: String {
        switch self {
        case .plainText: "txt"
        case .html: "html"
        case .csv: "csv"
        case .json: "json"
        }
    }

    var documentFormat: DocumentFormat {
        switch self {
        case .plainText: .plainText
        case .html: .html
        case .csv: .csv
        case .json: .json
        }
    }

    var sampleInput: String {
        switch self {
        case .plainText:
            """
            Hello SwiftMarkItDown
            This text is passed through as Markdown.
            """
        case .html:
            """
            <html>
              <head><title>Ignored title</title></head>
              <body>
                <h1>Hello from iOS</h1>
                <p>Convert <strong>native Swift</strong> content.</p>
                <a href="https://example.com">Example</a>
              </body>
            </html>
            """
        case .csv:
            """
            Name,Note
            Swift,Native
            "Mark, It Down","CSV | escaped"
            """
        case .json:
            #"{"title":"Roadmap","formats":["txt","html","csv","json"]}"#
        }
    }
}

#Preview {
    ContentView()
}
