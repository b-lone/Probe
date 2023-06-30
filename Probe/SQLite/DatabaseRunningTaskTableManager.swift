//
//  DatabaseRunningTaskTableManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/30.
//

import Cocoa
import SQLite3

class DatabaseRunningTaskTableManager: BaseDatabaseTableManager<RunningTaskModel> {
    private let caseIdColomnName = "case_id"
    private let vidoOutputPathColomnName = "vido_output_path"
    private let templateIdsCountColomnName = "template_ids"
    
    init() {
        super.init(tableName: "running_tasks")
    }
    
    override var createTableSQL: String {
        """
        CREATE TABLE IF NOT EXISTS \(tableName)
        (
        \(idColomnName) INTEGER PRIMARY KEY,
        \(caseIdColomnName) INTEGER,
        \(vidoOutputPathColomnName) TEXT,
        \(templateIdsCountColomnName) TEXT
        )
        """
    }

    override var insertSQL: String {
        """
        INSERT OR REPLACE INTO \(tableName)
        (
        \(idColomnName),
        \(caseIdColomnName),
        \(vidoOutputPathColomnName),
        \(templateIdsCountColomnName)
        )
        VALUES
        (?, ?, ?, ?)
        """
    }
    
    override var insertPrepare: ((OpaquePointer?, RunningTaskModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.id)
            index += 1
            sqlite3_bind_int64(statement, index, model.caseId)
            index += 1
            sqlite3_bind_text(statement, index, (model.config.vidoOutputPath as NSString).utf8String, -1, nil)
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
        SET \(caseIdColomnName) = ?,
        \(vidoOutputPathColomnName) = ?,
        \(templateIdsCountColomnName) = ?
        WHERE \(idColomnName) = ?
        """
    }
    
    override var updatePrepare: ((OpaquePointer?, RunningTaskModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.caseId)
            index += 1
            sqlite3_bind_text(statement, index, (model.config.vidoOutputPath as NSString).utf8String, -1, nil)
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
    
    override var selectPrepare: ((OpaquePointer?) -> RunningTaskModel) {
        { statement in
            var index: Int32 = 0
            let id = sqlite3_column_int64(statement, index)
            index += 1
            let caseId = sqlite3_column_int64(statement, index)
            index += 1
            let vidoOutputPath = String(cString: sqlite3_column_text(statement, index))
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
            
            let config = RunningTaskConfig(vidoOutputPath: vidoOutputPath)
            
            let model = RunningTaskModel(id: id,
                                         caseId: caseId,
                                         config: config,
                                         templateIds: templateIds)
            return model
        }
    }
}
