//
//  LocalFileManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/20.
//

import Cocoa

class LocalFileManager: NSObject {
    private let rootPath = {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.path
    }()

}
