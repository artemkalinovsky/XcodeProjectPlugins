import Foundation
import PackagePlugin

@main
struct GenerateLocalisationEnumPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        return [
            .buildCommand(
                displayName: "Running GenerateLocalisationEnumPlugin for \(target.name)",
                executable: try context.tool(named: "").path,
                arguments: []
            )
        ]
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

// MARK: - XcodeBuildToolPlugin

extension GenerateLocalisationEnumPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let localizableStringsInputFile = context.xcodeProject.directory.appending(
            subpath: "Localisation/Supporting Files/en.lproj/Localizable.strings"
        )
        let localizableStringsdictInputFile = context.xcodeProject.directory.appending(
            subpath: "Localisation/Supporting Files/en.lproj/Localizable.stringsdict"
        )
        let outputFile = context.xcodeProject.directory.appending(
            subpath: "Localisation/Generated Resources/LocalizationKey.swift"
        )

        let inputFiles = context.xcodeProject.directory.appending(
            subpath: "Localisation/Supporting Files/en.lproj"
        )
        let outputFiles = context.xcodeProject.directory.appending(
            subpath: "Localisation/Generated Resources"
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

        try outputFileContent.write(toFile: outputFile.string, atomically: true, encoding: .utf8)

        return [
            .buildCommand(
                displayName: "Running GenerateLocalisationEnumPlugin for \(target.displayName)",
                executable: try context.tool(named: "").path,
                arguments: [],
                inputFiles: [inputFiles],
                outputFiles: [outputFiles]
            )
        ]
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
