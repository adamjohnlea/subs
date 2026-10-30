import SwiftTUI

@main
struct SubsApp: App {
    /// `subs set-claude-key` is the only verb. SwiftTUI parses it before the
    /// runtime starts, so it never enters the TUI.
    nonisolated static let configuration = CommandConfiguration(
        commandName: "subs",
        subcommands: [CompletionsCommand.self, SetClaudeKeyCommand.self]
    )

    var body: some Scene {
        WindowGroup("subs", id: WindowIdentifier("subs")) {
            RootView()
        }
    }

    nonisolated static func swiftTUIRootSubcommand(
        forRawArguments arguments: [String]
    ) throws -> (any ParsableCommand)? {
        try registeredSubcommand(forRawArguments: arguments)
    }
}
