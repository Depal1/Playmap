import ArgumentParser

struct Playmap: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A CLI tool to modify PlayCover's Playmap files.",
        subcommands: [Layout.self, Fetch.self]
    )

    init() {}
}

Playmap.main()