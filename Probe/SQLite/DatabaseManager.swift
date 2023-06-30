//
//  DatabaseManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/21.
//

import Cocoa

class DatabaseManager: NSObject {
    var caseTableManager = DatabaseCaseTableManager()
    var templateTableManager = DatabaseTemplateTableManager()
    var resultTableManager = DatabaseResultTableManager()
    var frameRenderingTimeTableManager = DatabaseFrameRenderingTimeTableManager()
    var runningTaskTableManager = DatabaseRunningTaskTableManager()
    
    override init() {
        caseTableManager.createTableIfNotExits()
        templateTableManager.createTableIfNotExits()
        resultTableManager.createTableIfNotExits()
        frameRenderingTimeTableManager.createTableIfNotExits()
        runningTaskTableManager.createTableIfNotExits()
    }
}
