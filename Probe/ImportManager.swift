//
//  ImportManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa

class ImportManager: NSObject {
    func importFromFile(_ completedHandler: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true

        openPanel.begin { (result) -> Void in
            completedHandler(openPanel.url)
        }
    }

    func parseFile(_ path: String) -> [String] {
        do {
            var fileContent = try String(contentsOfFile: path, encoding: .utf8)
            fileContent = fileContent.trimmingCharacters(in: .whitespacesAndNewlines)
            let lines = fileContent.components(separatedBy: "\n")
            var cleanedLines: [String] = []

            for line in lines {
                let cleanedLine = line.trimmingCharacters(in: .whitespaces)
                cleanedLines.append(cleanedLine)
            }
            
            return cleanedLines
        } catch {
            print("Error reading file: \(error)")
        }
        return []
    }
}
