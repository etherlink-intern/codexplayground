# Native and FOSS Converter Backend Plan

This document records the likely native/FOSS backends for the reserved document formats in `DocumentFormat`. These are **not package dependencies yet**; the current release still returns `unsupportedFormat` for PDF, DOCX, PPTX, and XLSX. The goal is to keep the app's import UI honest while making the implementation path explicit.

## Short answer: are these simple to add?

They are straightforward to integrate as Swift Package / Apple-framework building blocks, but they are not all equally "drop-in" as Markdown converters:

| Format | Proposed backend | Integration effort | Why |
| --- | --- | --- | --- |
| PDF | Apple's PDFKit | Low for embedded text; medium when OCR fallback is included. | PDFKit is built into Apple platforms and can extract text from many PDFs, but scanned/image-only PDFs still need page rendering plus Vision OCR. |
| DOCX | ZIPFoundation + OOXML parsing | Medium. | DOCX is a ZIP of XML parts, but useful Markdown needs document body parsing, relationships, styles, numbering, tables, hyperlinks, and images. |
| PPTX | ZIPFoundation + OOXML parsing | Medium-high. | PPTX uses the same OpenXML ZIP structure, but slide ordering, shapes, notes, and layout-driven reading order make Markdown extraction more involved than DOCX. |
| XLSX | CoreXLSX + its transitive ZIPFoundation/XMLCoder graph | Medium-low for worksheet tables; medium for richer workbooks. | CoreXLSX already parses XLSX structure in Swift, but Markdown output still needs shared strings, sheet selection, empty-cell handling, formulas, merged cells, and table shaping decisions. Its dependency graph must be acknowledged alongside the direct package. |

## Backend source acknowledgements

When one of these backends is implemented, the PR that adds it should also add the dependency/framework acknowledgement to this table and to any required license notice files.

| Backend | Source | License / status | Intended use |
| --- | --- | --- | --- |
| Apple PDFKit | <https://developer.apple.com/documentation/pdfkit> | Apple system framework; no SwiftPM dependency. | PDF text extraction and optional page rendering for OCR fallback on Apple platforms. |
| ZIPFoundation | <https://github.com/weichsel/ZIPFoundation> | MIT-licensed Swift package. | ZIP container access for DOCX and PPTX OpenXML parts. |
| CoreXLSX | <https://github.com/CoreOffice/CoreXLSX> | Apache-2.0-licensed Swift package. | Read-only parsing of XLSX workbooks and worksheets. |
| XMLCoder | <https://github.com/maxdesiatov/XMLCoder> | MIT-licensed Swift package; transitive dependency of CoreXLSX. | XML decoding support used by CoreXLSX when mapping XLSX XML parts into Swift models. |
| Office Open XML structure | <https://ecma-international.org/publications-and-standards/standards/ecma-376/> | Published standard. | Format reference for DOCX/PPTX/XLSX XML parts and relationships. |

> Verification note: as of the current dependency review, CoreXLSX declares both XMLCoder and ZIPFoundation as SwiftPM dependencies. That means an XLSX converter PR must include acknowledgements for CoreXLSX itself **and** for each transitive dependency that ships in the resolved dependency graph.

## Recommended implementation order

1. **PDF text extraction with PDFKit**
   - Add a `PDFConverter` behind `#if canImport(PDFKit)`.
   - Extract embedded page text first.
   - If a page has no embedded text, optionally render the page and reuse the Vision OCR path already used by image ingestion.
   - Keep non-Apple platforms returning `unsupportedFormat` unless a separate cross-platform PDF backend is added.

2. **Shared OpenXML ZIP infrastructure**
   - Add ZIPFoundation as a SwiftPM dependency only when DOCX or PPTX work starts.
   - Build a small internal helper for reading XML parts, relationships, content types, and document metadata from OpenXML packages.
   - Use this helper for DOCX first, then PPTX.

3. **DOCX converter**
   - Parse `word/document.xml` in document order.
   - Resolve relationships for hyperlinks and images.
   - Map paragraphs, headings, lists, tables, emphasis, and links to Markdown.
   - Add fixtures that cover common Word exports rather than only hand-written XML.

4. **PPTX converter**
   - Parse slide order from `ppt/presentation.xml` and slide relationship parts.
   - Extract text from shapes, grouped shapes, speaker notes, and tables.
   - Use simple slide-section Markdown first; improve layout ordering later.

5. **XLSX converter with CoreXLSX**
   - Add CoreXLSX as a SwiftPM dependency when XLSX implementation begins.
   - Re-run SwiftPM dependency resolution and record the full resolved graph, including CoreXLSX transitive packages such as XMLCoder and ZIPFoundation.
   - Convert each selected worksheet to Markdown tables.
   - Decide how to handle formulas, empty rows/columns, merged cells, dates, and multiple sheets.

## Dependency policy

- Do not add ZIPFoundation or CoreXLSX to `Package.swift` until a converter actually uses them.
- Prefer conditional compilation for Apple-only frameworks such as PDFKit and Vision.
- Keep unsupported formats visible in `DocumentFormat` so apps can show useful import affordances and friendly `unsupportedFormat` errors.
- Add license acknowledgements in the same PR that introduces any FOSS dependency.
- Verify and acknowledge the **full resolved SwiftPM dependency graph**, not just direct dependencies. For example, a CoreXLSX-based converter must also account for its transitive XMLCoder and ZIPFoundation packages.
- Refresh dependency acknowledgements whenever `Package.resolved` changes so newly added, removed, or upgraded transitive packages are not missed.
