//
//  CaseCacheManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/20.
//

import Cocoa
import SQLite3

class CaseCacheManager: NSObject {
    private var databaseWrapper: SQLiteDatabaseWrapper
    private var database: OpaquePointer? {
        databaseWrapper.database
    }
    
    private let tableName = "test_cases"
    
    private let idColomnName = "id"
    private let nameColomnName = "name"
    
    init(database: SQLiteDatabaseWrapper) {
        self.databaseWrapper = database
    }
    
    func createTable(_ models: [TestCaseModel]) {
        let dropTableQuery = "DROP TABLE IF EXISTS \(tableName)"
        if sqlite3_exec(database, dropTableQuery, nil, nil, nil) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(database))
            print("error dropping table: \(errorMessage)")
        }
        
        
        let createTableSQL = """
        CREATE TABLE IF NOT EXISTS \(tableName) (
            \(idColomnName) INTEGER PRIMARY KEY,
            \(nameColomnName) TEXT
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
        
        for model in models {
            insert(model)
        }
    }
    
    func insert(_ model: TestCaseModel) {
        let insertSQL = """
        INSERT INTO \(tableName)
        (\(idColomnName),
        \(nameColomnName)
        VALUES
        (?, ?)
        """
        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertSQL, -1, &insertStatement, nil) == SQLITE_OK {
            var index: Int32 = 1
            sqlite3_bind_int64(insertStatement, index, model.id)
            index += 1
            sqlite3_bind_text(insertStatement, index, (model.name as NSString).utf8String, -1, nil)

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
    
    func remove(_ model: TestCaseModel) {
        let deleteSQL = "DELETE FROM \(tableName) WHERE \(idColomnName) = ?"
        var deleteStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_int64(deleteStatement, 1, model.id)

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
    
    func update(_ model: TestCaseModel) {
        let updateSQL = """
        UPDATE \(tableName) SET
        \(nameColomnName) = ?
        WHERE \(idColomnName) = ?
        """
        var updateStatement: OpaquePointer?

        if sqlite3_prepare_v2(database, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
            var index: Int32 = 1
            sqlite3_bind_text(updateStatement, index, (model.name as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(updateStatement, index, model.id)

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
    
    func select() -> [TestCaseModel] {
        let selectSQL = "SELECT * FROM \(tableName) ORDER BY \(idColomnName)"
        var selectStatement: OpaquePointer?

        var models = [TestCaseModel]()
        if sqlite3_prepare_v2(database, selectSQL, -1, &selectStatement, nil) == SQLITE_OK {
            while sqlite3_step(selectStatement) == SQLITE_ROW {
                var index: Int32 = 0
                let id = sqlite3_column_int64(selectStatement, index)
                index += 1
                let name = String(cString: sqlite3_column_text(selectStatement, index))
                let model = TestCaseModel(id: id, name: name)
                
                models.append(model)
            }
        } else {
            print("Failed to prepare select statement.")
        }

        sqlite3_finalize(selectStatement)
        
        return models
    }
}
