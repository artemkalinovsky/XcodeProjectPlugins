import Foundation
import ArgumentParser

@main
struct GenerateLocalisationEnumExecutable: ParsableCommand {
    @Option(help: "The path where the generated files will be created")
    var output: String

    func run() throws {
        let path = "Localisation/Supporting Files/en.lproj/"
        let stringsURL = URL(fileURLWithPath: path + "Localizable.strings")
        let stringsdictURL = URL(fileURLWithPath: path + "Localizable.stringsdict")
//        let outputURL = URL(fileURLWithPath: "Localisation/Generated Resources/LocalizationKey.swift")
        debugPrint(stringsURL)

        var outputFileContent = GenerateLocalisationEnumExecutable.template

        if let strings = NSDictionary(contentsOf: stringsURL) as? Dictionary<String, Any> {
            var output = ""
            for key in strings.keys.sorted() {
                output += "case \(fixKeyName(key)) = \"\(key)\"\n"
            }
            outputFileContent = outputFileContent.replacingOccurrences(of: "{KEYS}", with: output)
        }

        let stringsDict = try PropertyListSerialization.propertyList(
            from: try Data(contentsOf: stringsdictURL),
            options: .mutableContainers,
            format: nil
        ) as? [String: Any]

        if let stringsDict {
            var output = ""
            for key in stringsDict.keys.sorted() {
                output += "case \(fixKeyName(key))\n"
            }
            outputFileContent = outputFileContent.replacingOccurrences(of: "{PLURALS}", with: output)
        }

        debugPrint("Output File URL: \(output)")

        try URL(string: output).map {
            try outputFileContent.write(to: $0, atomically: true, encoding: .utf8)
        }

        debugPrint("Output File Content: \(outputFileContent)")
     }
}

// MARK: - Private

private extension GenerateLocalisationEnumExecutable {
    static let template = """
    // swiftlint:disable all
    // Autogenerated do not modify

    public enum LocalizationKey: String {

    {KEYS}

    public enum Plurals: String {
    {PLURALS}
    }
    }

    // MARK: CaseIterable

    extension LocalizationKey: CaseIterable { }
    // swiftlint:enable all
    """

    func fixKeyName(_ key: String) -> String {
        guard !key.isEmpty else { return "" }
        var out = key
        for check in [".", " "] {
            out = out.replacingOccurrences(of: check, with: "_")
        }
        return out.prefix(1).lowercased() + out.dropFirst()
    }
}
