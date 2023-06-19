//
//  CacheManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa
import SQLite3

class CacheManager: NSObject {
    private var database: OpaquePointer?
    private let tableName = "my_table"
    private let idColomnName = "id"
    private let stateColomnName = "state"
    private let useMontageColomnName = "use_montage"
    private let startMemoryColomnName = "start_memory"
    private let endMemoryColomnName = "end_memory"
    private let maxMemoryColomnName = "max_memory"
    private let durationColomnName = "duration"
    private let errorColomnName = "error_msg"
    private let filePathColomnName = "file_path"
    
    deinit {
        if let database = database {
            sqlite3_close(database)
        }
    }
    
    func setup() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let databaseURL = documentsURL.appendingPathComponent("database.db")

        if sqlite3_open(databaseURL.path, &database) == SQLITE_OK {
            print("Database opened successfully")
        } else {
            print("Failed to open database")
        }
    }
    
    func createTable(_ templateModels: [TemplateModel]) {
        let dropTableQuery = "DROP TABLE IF EXISTS \(tableName)"
        if sqlite3_exec(database, dropTableQuery, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            print("error dropping table: \(errorMessage)")
        }
        
        
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS \(tableName) (
            \(idColomnName) INTEGER PRIMARY KEY,
            \(stateColomnName) INTEGER,
            \(useMontageColomnName) INTEGER,
            \(startMemoryColomnName) INTEGER,
            \(endMemoryColomnName) INTEGER,
            \(maxMemoryColomnName) INTEGER,
            \(durationColomnName) INTEGER,
            \(errorColomnName) TEXT,
            \(filePathColomnName) TEXT
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
        
        for templateModel in templateModels {
            insert(templateModel)
        }
    }
    
    func insert(_ templateModel: TemplateModel) {
        let insertSQL = """
        INSERT INTO \(tableName)
        (\(idColomnName),
        \(stateColomnName),
        \(useMontageColomnName),
        \(startMemoryColomnName),
        \(endMemoryColomnName),
        \(maxMemoryColomnName),
        \(durationColomnName),
        \(errorColomnName),
        \(filePathColomnName))
        VALUES
        (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(insertStatement, 1, (templateModel.id as NSString).intValue)
            sqlite3_bind_int(insertStatement, 2, Int32(templateModel.state.rawValue))
            sqlite3_bind_int(insertStatement, 3, templateModel.useMontage ? 1 : 0)
            sqlite3_bind_int(insertStatement, 4, Int32(templateModel.startMemory))
            sqlite3_bind_int(insertStatement, 5, Int32(templateModel.endMemory))
            sqlite3_bind_int(insertStatement, 6, Int32(templateModel.maxMemory))
            sqlite3_bind_int(insertStatement, 7, Int32(templateModel.duration))
            sqlite3_bind_text(insertStatement, 8, templateModel.errorMsg ?? "", -1, nil)
            sqlite3_bind_text(insertStatement, 9, templateModel.filePath ?? "", -1, nil)

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
    
    func remove() {
        let deleteSQL = "DELETE FROM your_table WHERE column1 = ?"
        var deleteStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, "value1", -1, nil)

            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
            } else {
                print("Failed to delete row.")
            }
        } else {
            print("Failed to prepare delete statement.")
        }

        sqlite3_finalize(deleteStatement)
    }
    
    func update(_ templateModel: TemplateModel) {
        let updateSQL = """
        UPDATE \(tableName) SET
        \(stateColomnName) = ?,
        \(useMontageColomnName) = ?,
        \(startMemoryColomnName) = ?,
        \(endMemoryColomnName) = ?,
        \(maxMemoryColomnName) = ?,
        \(durationColomnName) = ?,
        \(errorColomnName) = ?,
        \(filePathColomnName) = ?
        WHERE \(idColomnName) = ?
        """
        var updateStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(updateStatement, 1, Int32(templateModel.state.rawValue))
            sqlite3_bind_int(updateStatement, 2, templateModel.useMontage ? 1 : 0)
            sqlite3_bind_int(updateStatement, 3, Int32(templateModel.startMemory))
            sqlite3_bind_int(updateStatement, 4, Int32(templateModel.endMemory))
            sqlite3_bind_int(updateStatement, 5, Int32(templateModel.maxMemory))
            sqlite3_bind_int(updateStatement, 6, Int32(templateModel.duration))
            sqlite3_bind_text(updateStatement, 7, ((templateModel.errorMsg ?? "") as NSString).utf8String , -1, nil)
            sqlite3_bind_text(updateStatement, 8, ((templateModel.filePath ?? "") as NSString).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 9, (templateModel.id as NSString).intValue)

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Failed to update row.")
            }
        } else {
            print("Failed to prepare update statement.")
        }

        sqlite3_finalize(updateStatement)
    }
    
    func select() -> [TemplateModel] {
        let selectSQL = "SELECT * FROM \(tableName) ORDER BY \(idColomnName)"
        var selectStatement: OpaquePointer?

        var templateModels = [TemplateModel]()
        if sqlite3_prepare_v2(database, selectSQL, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                let id = sqlite3_column_int64(selectStatement, 0)
                
                let templateModel = TemplateModel(id: "\(id)")
                templateModel.state = TemplateModel.State(rawValue: Int(sqlite3_column_int(selectStatement, 1))) ?? .ready
                templateModel.useMontage = sqlite3_column_int64(selectStatement, 2) == 1
                templateModel.startMemory = Int(sqlite3_column_int(selectStatement, 3))
                templateModel.endMemory = Int(sqlite3_column_int(selectStatement, 4))
                templateModel.maxMemory = Int(sqlite3_column_int(selectStatement, 5))
                templateModel.duration = Int(sqlite3_column_int(selectStatement, 6))
                let error = String(cString: sqlite3_column_text(selectStatement, 7))
                templateModel.errorMsg = error
                let filePath = String(cString: sqlite3_column_text(selectStatement, 8))
                templateModel.filePath = filePath
                
                templateModels.append(templateModel)
            }
        } else {
            print("Failed to prepare select statement.")
        }

        sqlite3_finalize(selectStatement)
        
        return templateModels
    }
}
