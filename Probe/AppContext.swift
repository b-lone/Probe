//
//  AppContext.swift
//  Probe
//
//  Created by Archie You on 2023/6/21.
//

import Cocoa

class AppContext: NSObject {
    static let shared = AppContext()
    
    let fileManager = LocalFileManager()
    
    let databaseWrapper = {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let databaseURL = documentsURL.appendingPathComponent("database_v2.db")
        return SQLiteDatabaseWrapper(databasePath: databaseURL.path)
    }()
    lazy var caseManager = CaseManager()
    lazy var runningManager = RunningManager()
}
