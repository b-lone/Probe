//
//  BaseDatabaseTableManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/29.
//

import Cocoa

import SQLite3

protocol DatabaseModelProtocol: AnyObject {
    var id: Int64 { get }
}

class BaseDatabaseTableManager<ModelType: NSObject & DatabaseModelProtocol>: NSObject {
    var databaseWrapper: SQLiteDatabaseWrapper {
        AppContext.shared.databaseWrapper
    }
    var database: OpaquePointer? {
        databaseWrapper.database
    }
    
    let tableName: String
    
    let idColomnName = "id"
    
    var tableExists: Bool { checkTableExists() }
    
    init(tableName: String) {
        self.tableName = tableName
    }
    
    func checkTableExists() -> Bool {
        var statement: OpaquePointer?
        let query = "SELECT name FROM sqlite_master WHERE type='table' AND name='\(tableName)';"
        
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        
        return false
    }
    
    func checkColumnExists(columnName: String) -> Bool {
        var statement: OpaquePointer?
        var columnExists = false
        
        let query = "PRAGMA table_info(\(tableName))"
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK else {
            print("Failed to prepare statement")
            return columnExists
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            if let existingColumnName = getColumnText(statement: statement, columnIndex: 1) {
                if existingColumnName == columnName {
                    columnExists = true
                    break
                }
            }
        }
        sqlite3_finalize(statement)
        return columnExists
    }
    
    private func getColumnText(statement: OpaquePointer?, columnIndex: Int32) -> String? {
        if let cText = sqlite3_column_text(statement, columnIndex) {
            let text = String(cString: cText)
            return text
        }
        return nil
    }
    
    var createTableSQL: String {
        """
        CREATE TABLE IF NOT EXISTS \(tableName)
        """
    }
    func createTableIfNotExits() {
        guard !tableExists else { return }
        
        var createTableStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, createTableSQL, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("[Database][\(tableName)]Table created successfully")
            } else {
                print("[Database][\(tableName)]Failed to create table")
            }
        } else {
            print("[Database][\(tableName)]Failed to prepare create table statement")
        }

        sqlite3_finalize(createTableStatement)
    }
    
    func dropTable() {
        let dropTableQuery = "DROP TABLE IF EXISTS \(tableName)"
        if sqlite3_exec(database, dropTableQuery, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            print("[Database][\(tableName)]error dropping table: \(errorMessage)")
        } else {
            print("[Database][\(tableName)]Table dropped successfully")
        }
    }
    
    func addColumn(_ columnName: String, _ type: String) {
        let query = "ALTER TABLE \(tableName) ADD COLUMN \(columnName) \(type)"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("[Database][\(tableName)]Column add successfully")
            } else {
                print("[Database][\(tableName)]Failed to add column")
            }
        } else {
            print("[Database][\(tableName)]Failed to prepare add column statement")
        }
        
        sqlite3_finalize(statement)
    }
    
    func insert(_ models: [ModelType]) {
        for model in models {
            insert(model)
        }
    }
    var insertSQL: String {
        ""
    }
    var insertPrepare: ((OpaquePointer?, ModelType)->Void) {
        {_, _ in}
    }
    func insert(_ model: ModelType) {
        createTableIfNotExits()
        
        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
            insertPrepare(insertStatement, model)

            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("[Database][\(tableName)]Successfully inserted row.")
            } else {
                print("[Database][\(tableName)]Failed to insert row.")
            }
        } else {
            print("[Database][\(tableName)]Failed to prepare insert statement.")
        }

        sqlite3_finalize(insertStatement)
    }
    
    var deleteSQL: String { "DELETE FROM \(tableName) WHERE \(idColomnName) = ?" }
    var deletePrepare: ((OpaquePointer?, ModelType) -> Void) {
        { statement, model in
            sqlite3_bind_int64(statement, 1, model.id)
        }
    }
    func delete(_ model: ModelType) {
        guard tableExists else { return }
        
        var deleteStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            deletePrepare(deleteStatement, model)

            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("[Database][\(tableName)]Successfully deleted row.")
            } else {
                print("[Database][\(tableName)]Failed to delete row.")
            }
        } else {
            print("[Database][\(tableName)]Failed to prepare delete statement.")
        }

        sqlite3_finalize(deleteStatement)
    }
    
    var updateSQL: String { "" }
    var updatePrepare: ((OpaquePointer?, ModelType)->Void) {
        {_, _ in}
    }
    func update(_ model: ModelType) {
        guard tableExists else { return }
        
        var updateStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
            updatePrepare(updateStatement, model)

            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("[Database][\(tableName)]Successfully updated row.")
            } else {
                print("[Database][\(tableName)]Failed to update row.")
            }
        } else {
            print("[Database][\(tableName)]Failed to prepare update statement.")
        }

        sqlite3_finalize(updateStatement)
    }
    
    var selectSQL: String {  "SELECT * FROM \(tableName) ORDER BY \(idColomnName)" }
    var selectPrepare: ((OpaquePointer?)->ModelType) {
        {_ in return ModelType()}
    }
    func select() -> [ModelType] {
        guard tableExists else { return[] }
        
        var selectStatement: OpaquePointer?

        var models = [ModelType]()
        if sqlite3_prepare_v2(database, selectSQL, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                let model = selectPrepare(selectStatement)
                models.append(model)
            }
        } else {
            print("[Database][\(tableName)]Failed to prepare select statement.")
        }

        sqlite3_finalize(selectStatement)
        
        return models
    }
    
//    private func executeSql(_ sql: String, _ model: ModelType) -> OpaquePointer? {
//        var statement: OpaquePointer?
//
//        if sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK {
//            updatePrepare(statement, model)
//
//            if sqlite3_step(statement) == SQLITE_DONE {
//                print("[\(tableName)]Successfully updated row.")
//            } else {
//                print("[\(tableName)]Failed to update row.")
//            }
//        } else {
//            print("[\(tableName)]Failed to prepare select statement.")
//        }
//
//        sqlite3_finalize(statement)
//
//        return statement
//    }
}
