//
//  DatabaseTemplateTableManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa
import SQLite3

class DatabaseTemplateTableManager: NSObject {
    private var databaseWrapper: SQLiteDatabaseWrapper
    private var database: OpaquePointer? {
        databaseWrapper.database
    }
    
    private let caseId: Int64
    private let tableName: String
    private var frameRenderingTimeTableManagers = [String : DatabaseFrameRenderingTimeTableManager]()
    
    private let idColomnName = "id"
    private let nameColomnName = "name"
    private let stateColomnName = "state"
    private let useMontageColomnName = "use_montage"
    private let useMontageFlagColomnName = "use_montage_flag"
    private let startMemoryColomnName = "start_memory"
    private let endMemoryColomnName = "end_memory"
    private let maxMemoryColomnName = "max_memory"
    private let durationColomnName = "duration"
    private let errorColomnName = "error_msg"
    private let filePathColomnName = "file_path"
    
    init(database: SQLiteDatabaseWrapper, caseId: Int64) {
        self.databaseWrapper = database
        self.caseId = caseId
        self.tableName = "templates_\(caseId)"
    }
    
    private func createTable() {
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS \(tableName) (
            \(idColomnName) INTEGER PRIMARY KEY,
            \(nameColomnName) TEXT,
            \(stateColomnName) INTEGER,
            \(useMontageColomnName) INTEGER,
            \(useMontageFlagColomnName) TEXT,
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
    }

    func createTable(_ templateModels: [TemplateModel]) {
        dropTable()
        
        createTable()
        
        for templateModel in templateModels {
            insert(templateModel)
        }
    }
    
    func dropTable() {
        let dropTableQuery = "DROP TABLE IF EXISTS \(tableName)"
        if sqlite3_exec(database, dropTableQuery, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            print("error dropping table: \(errorMessage)")
        }
    }
    
    func insert(_ model: TemplateModel) {
        let insertSQL = """
        INSERT INTO \(tableName)
        (\(idColomnName),
        \(nameColomnName),
        \(stateColomnName),
        \(useMontageColomnName),
        \(useMontageFlagColomnName),
        \(startMemoryColomnName),
        \(endMemoryColomnName),
        \(maxMemoryColomnName),
        \(durationColomnName),
        \(errorColomnName),
        \(filePathColomnName))
        VALUES
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
            var index: Int32 = 1
            sqlite3_bind_int64(insertStatement, index, sqlite3_int64((model.id as NSString).integerValue))
            index += 1
            sqlite3_bind_text(insertStatement, index, (model.name as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int(insertStatement, index, Int32(model.state.rawValue))
            index += 1
            sqlite3_bind_int(insertStatement, index, model.useMontage ? 1 : 0)
            index += 1
            sqlite3_bind_text(insertStatement, index, ((model.useMontageFlag ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int(insertStatement, index, Int32(model.startMemory))
            index += 1
            sqlite3_bind_int(insertStatement, index, Int32(model.endMemory))
            index += 1
            sqlite3_bind_int(insertStatement, index, Int32(model.maxMemory))
            index += 1
            sqlite3_bind_int(insertStatement, index, Int32(model.duration))
            index += 1
            sqlite3_bind_text(insertStatement, index, ((model.errorMsg ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_text(insertStatement, index, ((model.filePath ?? "") as NSString).utf8String, -1, nil)

            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Failed to insert row.")
            }
        } else {
            print("Failed to prepare insert statement.")
        }

        sqlite3_finalize(insertStatement)
        
        if !model.frameRenderingTime.isEmpty {
            let manager = getFrameRenderingTimeTableManager(model.id)
            manager.createTable(model.frameRenderingTime)
        }
    }
    
    func delete(_ model: TemplateModel) {
        let deleteSQL = "DELETE FROM \(tableName) WHERE \(idColomnName) = ?"
        var deleteStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int64(deleteStatement, 1, sqlite3_int64((model.id as NSString).integerValue))

            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
            } else {
                print("Failed to delete row.")
            }
        } else {
            print("Failed to prepare delete statement.")
        }

        sqlite3_finalize(deleteStatement)
        
        let manager = getFrameRenderingTimeTableManager(model.id)
        manager.dropTable()
    }
    
    func update(_ model: TemplateModel) {
        let updateSQL = """
        UPDATE \(tableName) SET
        \(nameColomnName) = ?,
        \(stateColomnName) = ?,
        \(useMontageColomnName) = ?,
        \(useMontageFlagColomnName) = ?,
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
            var index: Int32 = 1
            sqlite3_bind_text(updateStatement, index, (model.name as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int(updateStatement, index, Int32(model.state.rawValue))
            index += 1
            sqlite3_bind_int(updateStatement, index, model.useMontage ? 1 : 0)
            index += 1
            sqlite3_bind_text(updateStatement, index, ((model.useMontageFlag ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int(updateStatement, index, Int32(model.startMemory))
            index += 1
            sqlite3_bind_int(updateStatement, index, Int32(model.endMemory))
            index += 1
            sqlite3_bind_int(updateStatement, index, Int32(model.maxMemory))
            index += 1
            sqlite3_bind_int(updateStatement, index, Int32(model.duration))
            index += 1
            sqlite3_bind_text(updateStatement, index, ((model.errorMsg ?? "") as NSString).utf8String , -1, nil)
            index += 1
            sqlite3_bind_text(updateStatement, index, ((model.filePath ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(updateStatement, index, sqlite3_int64((model.id as NSString).integerValue))

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Failed to update row.")
            }
        } else {
            print("Failed to prepare update statement.")
        }

        sqlite3_finalize(updateStatement)
        
        
        let manager = getFrameRenderingTimeTableManager(model.id)
        manager.dropTable()
        if !model.frameRenderingTime.isEmpty {
            manager.createTable(model.frameRenderingTime)
        }
    }
    
    func select() -> [TemplateModel] {
        let selectSQL = "SELECT * FROM \(tableName) ORDER BY \(idColomnName)"
        var selectStatement: OpaquePointer?

        var templateModels = [TemplateModel]()
        if sqlite3_prepare_v2(database, selectSQL, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                var index: Int32 = 0
                let id = sqlite3_column_int64(selectStatement, index)
                let templateModel = TemplateModel(id: "\(id)")
                index += 1
                let name = String(cString: sqlite3_column_text(selectStatement, index))
                templateModel.name = name
                index += 1
                templateModel.state = TemplateModel.State(rawValue: Int(sqlite3_column_int(selectStatement, index))) ?? .ready
                index += 1
                templateModel.useMontage = sqlite3_column_int64(selectStatement, index) == 1
                index += 1
                let useMontageFlag = String(cString: sqlite3_column_text(selectStatement, index))
                templateModel.useMontageFlag = useMontageFlag
                index += 1
                templateModel.startMemory = Int(sqlite3_column_int(selectStatement, index))
                index += 1
                templateModel.endMemory = Int(sqlite3_column_int(selectStatement, index))
                index += 1
                templateModel.maxMemory = Int(sqlite3_column_int(selectStatement, index))
                index += 1
                templateModel.duration = Int(sqlite3_column_int(selectStatement, index))
                index += 1
                let error = String(cString: sqlite3_column_text(selectStatement, index))
                templateModel.errorMsg = error
                index += 1
                let filePath = String(cString: sqlite3_column_text(selectStatement, index))
                templateModel.filePath = filePath
                
                templateModel.frameRenderingTime = getFrameRenderingTimeTableManager(templateModel.id).select()
                
                templateModels.append(templateModel)
            }
        } else {
            print("Failed to prepare select statement.")
        }

        sqlite3_finalize(selectStatement)
        
        return templateModels
    }
    
    private func getFrameRenderingTimeTableManager(_ id: String) -> DatabaseFrameRenderingTimeTableManager {
        if let manager = frameRenderingTimeTableManagers[id] {
            return manager
        } else {
            let manager = DatabaseFrameRenderingTimeTableManager(database: databaseWrapper, caseId: self.caseId, templateId: id)
            frameRenderingTimeTableManagers[id] = manager
            return manager
        }
    }
}
