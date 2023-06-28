//
//  DatabaseFrameRenderingTimeTableManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/28.
//

import Cocoa
import SQLite3

class DatabaseFrameRenderingTimeTableManager: NSObject {
    private var databaseWrapper: SQLiteDatabaseWrapper
    private var database: OpaquePointer? {
        databaseWrapper.database
    }
    
    private let tableName: String
    
    private let positionColomnName = "position"
    private let renderingTimeColomnName = "rendering_time"
    
    init(database: SQLiteDatabaseWrapper, caseId: Int64, templateId: String) {
        self.databaseWrapper = database
        self.tableName = "frame_rendering_time_\(caseId)_\(templateId)"
    }
    
    func createTable(_ renderingTimes:[Int64: Int64]) {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS \(tableName) (
            \(positionColomnName) INTEGER PRIMARY KEY,
            \(renderingTimeColomnName) INTEGER
        )
        """

        var createTableStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, createTableSQL, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Table created successfully")
            } else {
                print("Failed to create table")
            }
        } else {
            print("Failed to prepare create table statement")
        }

        sqlite3_finalize(createTableStatement)
        
        renderingTimes.forEach { self.insert($0)}
    }
    
    func dropTable() {
        let dropTableQuery = "DROP TABLE IF EXISTS \(tableName)"
        if sqlite3_exec(database, dropTableQuery, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            print("error dropping table: \(errorMessage)")
        }
    }
    
    private func insert(_ info:(key: Int64, value: Int64)) {
        let insertSQL = """
        INSERT INTO \(tableName)
        (\(positionColomnName),
        \(renderingTimeColomnName))
        VALUES
        (?, ?)
        """
        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
            var index: Int32 = 1
            sqlite3_bind_int64(insertStatement, index, info.key)
            index += 1
            sqlite3_bind_int64(insertStatement, index, info.value)

            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Failed to insert row.")
            }
        } else {
            print("Failed to prepare insert statement.")
        }

        sqlite3_finalize(insertStatement)
    }
    
    func select() -> [Int64: Int64] {
        let selectSQL = "SELECT * FROM \(tableName) ORDER BY \(positionColomnName)"
        var selectStatement: OpaquePointer?

        var frameRenderingTimes = [Int64: Int64]()
        if sqlite3_prepare_v2(database, selectSQL, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                var index: Int32 = 0
                let position = sqlite3_column_int64(selectStatement, index)
                index += 1
                let renderingTime = sqlite3_column_int64(selectStatement, index)
                
                
                frameRenderingTimes[position] = renderingTime
            }
        } else {
            print("Failed to prepare select statement.")
        }

        sqlite3_finalize(selectStatement)
        
        return frameRenderingTimes
    }
}
