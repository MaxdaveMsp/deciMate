import SwiftUI
import UniformTypeIdentifiers

struct CSVExportDocument: FileDocument {
    // Plain text so iOS doesn't try to open it as a spreadsheet
    static var readableContentTypes: [UTType] { [.plainText, .commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.plainText] }

    var text: String

    init(text: String = "") { self.text = text }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            text = string
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
