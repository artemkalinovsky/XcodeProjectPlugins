import Foundation
import PackagePlugin

@main
struct GenerateLocalisationEnumPlugin: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) throws {}
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

// MARK: - XcodeBuildToolPlugin

extension GenerateLocalisationEnumPlugin: XcodeCommandPlugin {
    func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
        let localizableStringsInputFile = context.xcodeProject.directory.appending(
            subpath: "Localisation/Supporting Files/en.lproj/Localizable.strings"
        )
        let localizableStringsdictInputFile = context.xcodeProject.directory.appending(
            subpath: "Localisation/Supporting Files/en.lproj/Localizable.stringsdict"
        )
        let outputFile = context.xcodeProject.directory.appending(
            subpath: "Localisation/Generated Resources/LocalizationKey.swift"
        )

        var outputFileContent = GenerateLocalisationEnumPlugin.template

        if let localizableStringsURL = URL(string: localizableStringsInputFile.string),
           let strings = NSDictionary(contentsOf: localizableStringsURL) as? Dictionary<String, Any> {
            var output = ""
            for key in strings.keys.sorted() {
                output += "case \(fixKeyName(key)) = \"\(key)\"\n"
            }
            outputFileContent = outputFileContent.replacingOccurrences(of: "{KEYS}", with: output)
        }

        let localizableStringsdictURL = URL(string: localizableStringsdictInputFile.string)
        let localizableStringsdictData = try localizableStringsdictURL.map { try Data(contentsOf: $0) }
        let stringsDict = try localizableStringsdictData.flatMap {
            try PropertyListSerialization.propertyList(
                from: $0,
                options: .mutableContainers,
                format: nil
            ) as? [String: Any]
        }
        if let stringsDict {
            var output = ""
            for key in stringsDict.keys.sorted() {
                output += "case \(fixKeyName(key))\n"
            }
            outputFileContent = outputFileContent.replacingOccurrences(of: "{PLURALS}", with: output)
        }

        let outputFileURL = URL(string: outputFile.string)
        try outputFileURL.map { try outputFileContent.write(to: $0, atomically: true, encoding: .utf8) }
    }
}
#endif

// MARK: - Private

private extension GenerateLocalisationEnumPlugin {
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
