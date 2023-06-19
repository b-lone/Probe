//
//  ExportManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/6/2.
//

import Cocoa

class ExportManager: NSObject {
    func exprot(_ templateModels: [TemplateModel]) {
        getSavePath { url in
            self.exprot(templateModels, url: url)
        }
    }
    
    func exportFailedIds(_ templateModels: [TemplateModel]) {
        getSavePath { url in
            self.exportFailedIds(templateModels, url: url)
        }
    }
    
    private func exportFailedIds(_ templateModels: [TemplateModel], url: URL) {
        let filePath = url.appendingPathComponent("failed_ids.txt")
        
        var fileContent = ""
        for templateModel in templateModels {
            if templateModel.state == .failed {
                fileContent += templateModel.id + "\n"
            }
        }
        
        do {
            try fileContent.write(to: filePath, atomically: true, encoding: .utf8)
            print("文件保存成功：\(filePath.path)")
        } catch {
            print("保存文件时出现错误：\(error.localizedDescription)")
        }
    }
    
    private func exprot(_ templateModels: [TemplateModel], url: URL) {
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
    
    private func getSavePath(_ completedHandler:@escaping (URL) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false

        openPanel.begin { (result) -> Void in
            if result == NSApplication.ModalResponse.OK {
                if let url = openPanel.url {
                    completedHandler(url)
                }
            }
        }
    }
}
