//
//  DatabaseResultTableManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/29.
//

import Cocoa
import SQLite3

class DatabaseResultTableManager: BaseDatabaseTableManager<ResultModel> {
    private let templateIdColomnName = "template_id"
    private let taskIdColomnName = "task_id"
    private let stateColomnName = "state"
    private let useMontageColomnName = "use_montage"
    private let montageAbilityColomnName = "montage_ability"
    private let montageAbilityFlagColomnName = "montage_ability_flag"
    private let startMemoryColomnName = "start_memory"
    private let endMemoryColomnName = "end_memory"
    private let maxMemoryColomnName = "max_memory"
    private let durationColomnName = "duration"
    private let errorColomnName = "error_msg"
    private let filePathColomnName = "file_path"
    
    private var onceFlag = true
    
    init() {
        super.init(tableName: "results")
    }
    
    override var createTableSQL: String {
        """
        CREATE TABLE IF NOT EXISTS \(tableName)
        (
        \(idColomnName) INTEGER PRIMARY KEY,
        \(templateIdColomnName) INTEGER,
        \(taskIdColomnName) INTEGER,
        \(stateColomnName) INTEGER,
        \(useMontageColomnName) INTEGER,
        \(montageAbilityColomnName) INTEGER,
        \(montageAbilityFlagColomnName) TEXT,
        \(startMemoryColomnName) INTEGER,
        \(endMemoryColomnName) INTEGER,
        \(maxMemoryColomnName) INTEGER,
        \(durationColomnName) INTEGER,
        \(errorColomnName) TEXT,
        \(filePathColomnName) TEXT
        )
        """
    }
    
//    override func createTableIfNotExits() {
//        super.createTableIfNotExits()
//
//        let copyDataQuery = """
//            INSERT INTO \(tableName)_v2 (
//            \(idColomnName),
//            \(templateIdColomnName),
//            \(taskIdColomnName),
//            \(stateColomnName),
//            \(montageAbilityColomnName),
//            \(montageAbilityFlagColomnName),
//            \(startMemoryColomnName),
//            \(endMemoryColomnName),
//            \(maxMemoryColomnName),
//            \(durationColomnName),
//            \(errorColomnName),
//            \(filePathColomnName)
//            )
//            SELECT
//            \(idColomnName),
//            \(templateIdColomnName),
//            \(taskIdColomnName),
//            \(stateColomnName),
//            use_montage,
//            use_montage_flag,
//            \(startMemoryColomnName),
//            \(endMemoryColomnName),
//            \(maxMemoryColomnName),
//            \(durationColomnName),
//            \(errorColomnName),
//            \(filePathColomnName)
//            FROM \(tableName);
//            """
//        var createTableStatement: OpaquePointer?
//
//        if sqlite3_prepare_v2(database, copyDataQuery, -1, &createTableStatement, nil) == SQLITE_OK {
//            if sqlite3_step(createTableStatement) == SQLITE_DONE {
//                print("[Database][\(tableName)]Table copy successfully")
//            } else {
//                print("[Database][\(tableName)]Failed to copy table")
//            }
//        } else {
//            print("[Database][\(tableName)]Failed to prepare copy table statement")
//        }
//
//        sqlite3_finalize(createTableStatement)
//
//        dropTable()
//
//        let renameTableQuery = "ALTER TABLE \(tableName)_v2 RENAME TO \(tableName);"
//        if sqlite3_prepare_v2(database, renameTableQuery, -1, &createTableStatement, nil) == SQLITE_OK {
//            if sqlite3_step(createTableStatement) == SQLITE_DONE {
//                print("[Database][\(tableName)]Table rename successfully")
//            } else {
//                print("[Database][\(tableName)]Failed to rename table")
//            }
//        } else {
//            print("[Database][\(tableName)]Failed to prepare rename table statement")
//        }
//
//        sqlite3_finalize(createTableStatement)
//    }

    override var insertSQL: String {
        """
        INSERT OR REPLACE INTO \(tableName)
        (
        \(idColomnName),
        \(templateIdColomnName),
        \(taskIdColomnName),
        \(stateColomnName),
        \(useMontageColomnName),
        \(montageAbilityColomnName),
        \(montageAbilityFlagColomnName),
        \(startMemoryColomnName),
        \(endMemoryColomnName),
        \(maxMemoryColomnName),
        \(durationColomnName),
        \(errorColomnName),
        \(filePathColomnName)
        )
        VALUES
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
    }
    
    override var insertPrepare: ((OpaquePointer?, ResultModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.id)
            index += 1
            sqlite3_bind_int64(statement, index, model.templateId)
            index += 1
            sqlite3_bind_int64(statement, index, model.taskId)
            index += 1
            sqlite3_bind_int(statement, index, Int32(model.state.rawValue))
            index += 1
            sqlite3_bind_int(statement, index, model.useMontage ? 1 : 0)
            index += 1
            sqlite3_bind_int(statement, index, model.montageAbility ? 1 : 0)
            index += 1
            sqlite3_bind_text(statement, index, ((model.montageAbilityFlag ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.startMemory)
            index += 1
            sqlite3_bind_int64(statement, index, model.endMemory)
            index += 1
            sqlite3_bind_int64(statement, index, model.maxMemory)
            index += 1
            sqlite3_bind_int64(statement, index, model.duration)
            index += 1
            sqlite3_bind_text(statement, index, ((model.errorMsg ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_text(statement, index, ((model.filePath ?? "") as NSString).utf8String, -1, nil)
        }
    }
    
    override var updateSQL: String {
        """
        UPDATE \(tableName)
        SET \(templateIdColomnName) = ?,
        \(taskIdColomnName) = ?,
        \(stateColomnName) = ?,
        \(useMontageColomnName) = ?,
        \(montageAbilityColomnName) = ?,
        \(montageAbilityFlagColomnName) = ?,
        \(startMemoryColomnName) = ?,
        \(endMemoryColomnName) = ?,
        \(maxMemoryColomnName) = ?,
        \(durationColomnName) = ?,
        \(errorColomnName) = ?,
        \(filePathColomnName) = ?
        WHERE \(idColomnName) = ?
        """
    }
    
    override var updatePrepare: ((OpaquePointer?, ResultModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.templateId)
            index += 1
            sqlite3_bind_int64(statement, index, model.taskId)
            index += 1
            sqlite3_bind_int64(statement, index, model.state.rawValue)
            index += 1
            sqlite3_bind_int64(statement, index, model.useMontage ? 1 : 0)
            index += 1
            sqlite3_bind_int64(statement, index, model.montageAbility ? 1 : 0)
            index += 1
            sqlite3_bind_text(statement, index, ((model.montageAbilityFlag ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.startMemory)
            index += 1
            sqlite3_bind_int64(statement, index, model.endMemory)
            index += 1
            sqlite3_bind_int64(statement, index, model.maxMemory)
            index += 1
            sqlite3_bind_int64(statement, index, model.duration)
            index += 1
            sqlite3_bind_text(statement, index, ((model.errorMsg ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_text(statement, index, ((model.filePath ?? "") as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.id)
        }
    }
    
    override var selectPrepare: ((OpaquePointer?) -> ResultModel) {
        { statement in
            var index: Int32 = 0
            let id = sqlite3_column_int64(statement, index)
            index += 1
            let templateId = sqlite3_column_int64(statement, index)
            index += 1
            let taskId = sqlite3_column_int64(statement, index)
            index += 1
            let state = ResultModel.State(rawValue: sqlite3_column_int64(statement, index)) ?? .ready
            index += 1
            let useMontage = sqlite3_column_int64(statement, index) == 1
            index += 1
            let montageAbility = sqlite3_column_int64(statement, index) == 1
            index += 1
            let montageAbilityFlag = String(cString: sqlite3_column_text(statement, index))
            index += 1
            let startMemory = sqlite3_column_int64(statement, index)
            index += 1
            let endMemory = sqlite3_column_int64(statement, index)
            index += 1
            let maxMemory = sqlite3_column_int64(statement, index)
            index += 1
            let duration = sqlite3_column_int64(statement, index)
            index += 1
            let errorMsg = String(cString: sqlite3_column_text(statement, index))
            index += 1
            let filePath = String(cString: sqlite3_column_text(statement, index))
            
            let model = ResultModel(id: id,
                                    templateId: templateId,
                                    taskId: taskId,
                                    state: state,
                                    useMontage: useMontage,
                                    montageAbility: montageAbility,
                                    montageAbilityFlag: montageAbilityFlag,
                                    startMemory: startMemory,
                                    endMemory: endMemory,
                                    maxMemory: maxMemory,
                                    duration: duration,
                                    errorMsg: errorMsg,
                                    filePath: filePath)
            return model
        }
    }
}
