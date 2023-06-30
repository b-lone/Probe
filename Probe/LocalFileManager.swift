//
//  LocalFileManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/20.
//

import Cocoa

class LocalFileManager: NSObject { 
    let rootPath = {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.path
    }()
    
    func getCasePath(_ model: TestCaseModel) -> String {
        let path = (rootPath as NSString).appendingPathComponent(model.name)
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                print("创建失败：\(path)")
            }
        }
        return path
    }
    
    func getVideoOutputPath(_ model: TestCaseModel) -> String {
        let path = (getCasePath(model) as NSString).appendingPathComponent("Video")
        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                print("创建失败：\(path)")
            }
        }
        return path
    }
    
    func getResultFilePath(_ model: TestCaseModel) -> String {
        return (getCasePath(model) as NSString).appendingPathComponent("result.txt")
    }
}
