//
//  TestCaseModel.swift
//  Probe
//
//  Created by Archie You on 2023/6/20.
//

import Cocoa

class TestCaseModel: NSObject {
    var id: Int64
    var name: String
    var templateModels = [TemplateModel]()
    
    init(id: Int64, name: String) {
        self.id = id
        self.name = name
    }
    
    convenience init(name: String) {
        let currentTime = Date().timeIntervalSince1970
        let timestampInMilliseconds = Int64(currentTime * 1000)
        self.init(id: timestampInMilliseconds, name: name)
    }
    
}
