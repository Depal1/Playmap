import Foundation
import ArgumentParser

struct Fetch: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Fetch and handle Playmap files from a URL or local directory."
    )

    @Argument(help: "The bundle ID of the keymap.")
    var bundleID: String = ""

    @Flag(help: "Fetch and print the README.md file if available.")
    var readme: Bool = false

    @Flag(help: "Prompt to download a file.")
    var download: Bool = false

    @Option(help: "The name of the GitHub repository (USERNAME/REPOSITORY) or local path to repository.")
    var source: String?

    func run() throws {
        let keymapURL: URL
        
        if let sourceURLString = source {
            if sourceURLString.hasPrefix("file://") {
                // Local directory
                guard let localURL = URL(string: sourceURLString+"\(bundleID)") else {
                    throw ValidationError("Invalid local directory URL.")
                }
                keymapURL = localURL
            } else {
                // GitHub repository URL
                guard let url = URL(string: "https://api.github.com/repos/\(sourceURLString)/contents/keymapping/\(bundleID)") else {
                    throw ValidationError("Invalid GitHub repository.")
                }
                keymapURL = url
            }
        } else {
            // Default GitHub repository URL
            keymapURL = URL(string: "https://api.github.com/repos/PlayCover/keymaps/contents/keymapping/\(bundleID)")!
        }

        // Fetch JSON contents
        var json: [[String: Any]]?
        if keymapURL.scheme == "file" {
            // Local file handling
            do {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(at: keymapURL, includingPropertiesForKeys: nil)
                json = contents.map { [$0.lastPathComponent: $0.absoluteString] }
            } catch {
                throw ValidationError("Error reading local directory: \(error)")
            }
        } else {
            // GitHub handling
            json = fetchJSON(from: keymapURL)
        }
        
        guard let files = json else {
            throw ValidationError("Failed to fetch or parse keymaps.")
        }

        print("Contents of directory \(bundleID):") 
        printFileNames(from: files)

        if readme {
            if let readmeContents = fetchReadme(from: files) {
                print("\nREADME.md contents:\n")
                print(readmeContents)
            } else {
                print("README.md not found in directory \(bundleID).")
            }
        }
        
        if download {
            print("\nEnter the name of the file you want to download:")
            if let fileName = readLine(), !fileName.isEmpty {
                if let file = files.first(where: { $0["name"] as? String == fileName }),
                   let downloadURLString = file["download_url"] as? String,
                   let downloadURL = URL(string: downloadURLString) {
                    
                    // Default download location
                    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
                    let defaultDirectory = homeDirectory.appendingPathComponent("Library/Containers/io.playcover.PlayCover/Keymapping")
                    
                    print("Enter custom download location or press Enter to use default location (\(defaultDirectory.path)):")
                    if let customLocation = readLine(), !customLocation.isEmpty {
                        // Custom download location
                        let customURL = URL(fileURLWithPath: customLocation).appendingPathComponent(fileName)
                        downloadFile(from: downloadURL, to: customURL)
                    } else {
                        // Default location with bundle ID as filename
                        let destinationURL = defaultDirectory.appendingPathComponent(fileName)
                        downloadFile(from: downloadURL, to: destinationURL)
                    }
                } else {
                    print("File not found.")
                }
            } else {
                print("Invalid file name.")
            }
        }
    }

    // Reuse functions from the previous script
    func fetchData(from url: URL) -> Data? {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: Data?
        
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Error fetching data: \(error)")
            } else {
                result = data
            }
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return result
    }

    func fetchJSON(from url: URL) -> [[String: Any]]? {
        guard let data = fetchData(from: url) else {
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                return json
            }
        } catch {
            print("Error parsing JSON: \(error)")
        }
        
        return nil
    }

    func printFileNames(from json: [[String: Any]]) {
        for file in json {
            if let name = file["name"] as? String {
                print(name)
            }
        }
    }

    func fetchReadme(from json: [[String: Any]]) -> String? {
        for file in json {
            if let name = file["name"] as? String, name.lowercased() == "readme.md",
               let downloadURL = file["download_url"] as? String,
               let url = URL(string: downloadURL) {
                return fetchContents(of: url)
            }
        }
        return nil
    }

    func fetchContents(of url: URL) -> String? {
        guard let data = fetchData(from: url) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func downloadFile(from url: URL, to destinationURL: URL) {
        let data = fetchData(from: url)
        do {
            try data?.write(to: destinationURL)
            print("File downloaded to \(destinationURL.path)")
        } catch {
            print("Error writing file: \(error)")
        }
    }
}

