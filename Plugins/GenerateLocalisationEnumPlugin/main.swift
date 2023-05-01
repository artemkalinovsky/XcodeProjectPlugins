import Foundation
import PackagePlugin

@main
struct GenerateLocalisationEnumPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        []
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GenerateLocalisationEnumPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        return [
            .buildCommand(
                displayName: "Generate Localisation Enum for \(target.displayName)",
                executable: try context.tool(named: "GenerateLocalisationEnumExecutable").path,
                arguments: []
            )
        ]
    }
}
#endif


