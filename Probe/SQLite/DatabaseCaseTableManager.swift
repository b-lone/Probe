//
//  DatabaseCaseTableManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/20.
//

import Cocoa
import SQLite3

class DatabaseCaseTableManager: BaseDatabaseTableManager<TestCaseModel> {
    private let nameColomnName = "name"
    private let templateIdsCountColomnName = "template_ids"
    
    init() {
        super.init(tableName: "test_cases")
    }
    
    override var createTableSQL: String {
        """
        CREATE TABLE IF NOT EXISTS \(tableName)
        (
        \(idColomnName) INTEGER PRIMARY KEY,
        \(nameColomnName) TEXT,
        \(templateIdsCountColomnName) TEXT
        )
        """
    }

    override var insertSQL: String {
        """
        INSERT OR REPLACE INTO \(tableName)
        (
        \(idColomnName),
        \(nameColomnName),
        \(templateIdsCountColomnName)
        )
        VALUES
        (?, ?, ?)
        """
    }
    
    override var insertPrepare: ((OpaquePointer?, TestCaseModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.id)
            index += 1
            sqlite3_bind_text(statement, index, (model.name as NSString).utf8String, -1, nil)
            index += 1
            var templateIds = ""
            if let jsonData = try? JSONEncoder().encode(model.templateIds),  let jsonString = String(data: jsonData, encoding: .utf8) {
                templateIds = jsonString
            }
            sqlite3_bind_text(statement, index, (templateIds as NSString).utf8String, -1, nil)
        }
    }
    
    override var updateSQL: String {
        """
        UPDATE \(tableName)
        SET \(nameColomnName) = ?,
        \(templateIdsCountColomnName) = ?
        WHERE \(idColomnName) = ?
        """
    }
    
    override var updatePrepare: ((OpaquePointer?, TestCaseModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_text(statement, index, (model.name as NSString).utf8String, -1, nil)
            index += 1
            var templateIds = ""
            if let jsonData = try? JSONEncoder().encode(model.templateIds),  let jsonString = String(data: jsonData, encoding: .utf8) {
                templateIds = jsonString
            }
            sqlite3_bind_text(statement, index, (templateIds as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.id)
        }
    }
    
    override var selectPrepare: ((OpaquePointer?) -> TestCaseModel) {
        { statement in
            var index: Int32 = 0
            let id = sqlite3_column_int64(statement, index)
            index += 1
            let name = String(cString: sqlite3_column_text(statement, index))
            index += 1
            let jsonString = String(cString: sqlite3_column_text(statement, index))
            var templateIds = [Int64]()
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    templateIds = try JSONDecoder().decode([Int64].self, from: jsonData)
                } catch {
                    print("Error decoding JSON to array: \(error)")
                }
            }
            
            let model = TestCaseModel(id: id, name: name, templateIds: templateIds)
            return model
        }
    }
}
