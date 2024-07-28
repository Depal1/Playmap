import Foundation
import ArgumentParser

enum Layouts: String, ExpressibleByArgument, Decodable {
    case qwerty = "QWERTY"
    case azerty = "AZERTY"
    case qwertz = "QWERTZ"
}

let layoutMappings: [Layouts: [Int: Int]] = [
    .qwerty: [:],  // No changes needed for QWERTY as it is the default layout
    .azerty: [
        24: 0,  // Q -> A
        23: 11, // W -> Z
        0: 24,  // A -> Q
        11: 23, // Z -> W
        41: 41  // M -> ;
    ],
    .qwertz: [
        28: 44, // Y -> Z
        44: 28  // Z -> Y
    ]
]

let reverseMappings: [Layouts: [Int: Int]] = [
    .azerty: [
        0: 24,  // A -> Q
        11: 23, // Z -> W
        24: 0,  // Q -> A
        23: 11, // W -> Z
        41: 41  // ; -> M
    ],
    .qwertz: [
        44: 28, // Z -> Y
        28: 44  // Y -> Z
    ]
]

func readFile(atPath path: String) -> String? {
    return try? String(contentsOfFile: path, encoding: .utf8)
}

func writeFile(_ content: String, toPath path: String) {
    try? content.write(toFile: path, atomically: true, encoding: .utf8)
}

func modifyLayout(inContent content: String, from fromLayout: Layouts, to toLayout: Layouts) -> String {
    var mappings: [Int: Int]

    if fromLayout == toLayout {
        return content
    }

    if toLayout == .qwerty {
        mappings = reverseMappings[fromLayout] ?? [:]
    } else {
        mappings = layoutMappings[toLayout] ?? [:]
    }

    var modifiedContent = content
    for (original, replacement) in mappings {
        modifiedContent = modifiedContent.replacingOccurrences(
            of: "<integer>\(original)</integer>",
            with: "<integer>\(replacement)</integer>"
        )
    }
    return modifiedContent
}

struct Layout: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Modify the layout of a Playmap file.",
        discussion: "This command reads a Playmap file, modifies its layout according to the specified from and to layouts, and writes the modified content to the output Playmap."
    )
    
    @Argument(help: "Path to the input file.")
    var inputFile: String
    
    @Argument(help: "Path to the output file.")
    var outputFile: String
    
    @Argument(help: "Current layout of the file: QWERTY, AZERTY, or QWERTZ.")
    var fromLayout: Layouts
    
    @Argument(help: "Desired layout of the file: QWERTY, AZERTY, or QWERTZ.")
    var toLayout: Layouts

    func run() throws {
        // Ensure the input file has a .playmap extension
        guard inputFile.hasSuffix(".playmap") else {
            throw ValidationError("The input file must have a .playmap extension.")
        }

        // Ensure the output file has a .playmap extension
        guard outputFile.hasSuffix(".playmap") else {
            throw ValidationError("The output file must have a .playmap extension.")
        }

        guard let content = readFile(atPath: inputFile) else {
            throw ValidationError("Failed to read input file.")
        }

        let modifiedContent = modifyLayout(inContent: content, from: fromLayout, to: toLayout)
        writeFile(modifiedContent, toPath: outputFile)
        print("Layout changed from \(fromLayout.rawValue) to \(toLayout.rawValue) and saved to \(outputFile)")
    }
}