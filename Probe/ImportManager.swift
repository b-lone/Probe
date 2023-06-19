//
//  ImportManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa

protocol ImportManagerDelegate: AnyObject {
    func importDidFinish(_ data: [String])
}

class ImportManager: NSObject {
    weak var delegate: ImportManagerDelegate?
    
    func importFromFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true

        openPanel.begin { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = openPanel.url {
                    self.parseFile(url)
                }
            }
        }
    }
    
    private func parseFile(_ url: URL) {
        do {
            var fileContent = try String(contentsOf: url, encoding: .utf8)
            fileContent = fileContent.trimmingCharacters(in: .whitespacesAndNewlines)
            let lines = fileContent.components(separatedBy: "\n")
            var cleanedLines: [String] = []

            for line in lines {
                let cleanedLine = line.trimmingCharacters(in: .whitespaces)
                cleanedLines.append(cleanedLine)
            }
            
            delegate?.importDidFinish(cleanedLines)
        } catch {
            print("Error reading file: \(error)")
        }
    }
}
