//
//  SQLiteDatabaseWrapper.swift
//  Probe
//
//  Created by Archie You on 2023/6/21.
//

import Cocoa
import SQLite3

class SQLiteDatabaseWrapper: NSObject {
    var database: OpaquePointer?
    
    deinit {
        if let database = database {
            sqlite3_close(database)
        }
    }
    
    init(databasePath: String) {
        if sqlite3_open(databasePath, &database) == SQLITE_OK {
            print("Database opened successfully")
        } else {
            print("Failed to open database")
        }
    }
}
