//
//  ExportManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/6/2.
//

import Cocoa

class ExportManager: NSObject {
    func exprot(_ templateModels: [TemplateModel]) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false

        openPanel.begin { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = openPanel.url {
                    self.saveToFile(templateModels, url: url)
                }
            }
        }
    }
    
    private func saveToFile(_ templateModels: [TemplateModel], url: URL) {
        let filePath = url.appendingPathComponent("result.txt")
        
        var fileContent = ""
        for templateModel in templateModels {
            fileContent += templateModel.description + "\n"
        }
        
        do {
            try fileContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("文件保存成功：\(filePath.path)")
        } catch {
            print("保存文件时出现错误：\(error.localizedDescription)")
        }
    }
}
