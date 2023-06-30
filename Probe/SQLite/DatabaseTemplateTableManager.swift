//
//  DatabaseTemplateTableManager.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/30.
//

import Cocoa
import SQLite3

class DatabaseTemplateTableManager: BaseDatabaseTableManager<TemplateModel> {
    private let nameColomnName = "name"
    private let sdkTagColomnName = "sdk_tag"
    private let caseIdsColomnName = "case_ids"
    private let usageColomnName = "usage"
    private let clipCountColomnName = "clip_count"
    private let canReplaceClipCountColomnName = "can_replace_clip_count"
    private let previewUrlColomnName = "preview_url"
    private let coverUrlColomnName = "cover_url"
    private let downloadUrlColomnName = "download_url"
    
    init() {
        super.init(tableName: "templates")
    }
    
    override var createTableSQL: String {
        """
        CREATE TABLE IF NOT EXISTS \(tableName)
        (
        \(idColomnName) INTEGER PRIMARY KEY,
        \(nameColomnName) TEXT,
        \(sdkTagColomnName) INTEGER,
        \(caseIdsColomnName) TEXT,
        \(usageColomnName) INTEGER,
        \(clipCountColomnName) INTEGER,
        \(canReplaceClipCountColomnName) INTEGER,
        \(previewUrlColomnName) TEXT,
        \(coverUrlColomnName) TEXT,
        \(downloadUrlColomnName) TEXT
        )
        """
    }
    
    override func createTableIfNotExits() {
        super.createTableIfNotExits()
        if !checkColumnExists(columnName: usageColomnName) {
            addColumn(usageColomnName, "INTEGER")
            addColumn(clipCountColomnName, "INTEGER")
            addColumn(canReplaceClipCountColomnName, "INTEGER")
            addColumn(previewUrlColomnName, "TEXT")
            addColumn(coverUrlColomnName, "TEXT")
            addColumn(downloadUrlColomnName, "TEXT")
        }
    }

    override var insertSQL: String {
        """
        INSERT OR REPLACE INTO \(tableName)
        (
        \(idColomnName),
        \(nameColomnName),
        \(sdkTagColomnName),
        \(caseIdsColomnName),
        \(usageColomnName),
        \(clipCountColomnName),
        \(canReplaceClipCountColomnName),
        \(previewUrlColomnName),
        \(coverUrlColomnName),
        \(downloadUrlColomnName)
        )
        VALUES
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
    }
    
    override var insertPrepare: ((OpaquePointer?, TemplateModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.id)
            index += 1
            sqlite3_bind_text(statement, index, (model.name as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.sdkTag ? 1 : 0)
            index += 1
            var caseIds = ""
            if let jsonData = try? JSONEncoder().encode(model.caseIds),  let jsonString = String(data: jsonData, encoding: .utf8) {
                caseIds = jsonString
            }
            sqlite3_bind_text(statement, index, (caseIds as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.usage)
            index += 1
            sqlite3_bind_int64(statement, index, model.clipCount)
            index += 1
            sqlite3_bind_int64(statement, index, model.canReplaceClipCount)
            index += 1
            sqlite3_bind_text(statement, index, (model.previewUrl as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_text(statement, index, (model.coverUrl as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_text(statement, index, (model.downloadUrl as NSString).utf8String, -1, nil)
        }
    }
    
    override var updateSQL: String {
        """
        UPDATE \(tableName)
        SET \(nameColomnName) = ?,
        \(sdkTagColomnName) = ?,
        \(caseIdsColomnName) = ?,
        \(usageColomnName) = ?,
        \(clipCountColomnName) = ?,
        \(canReplaceClipCountColomnName) = ?,
        \(previewUrlColomnName) = ?,
        \(coverUrlColomnName) = ?,
        \(downloadUrlColomnName) = ?
        WHERE \(idColomnName) = ?
        """
    }
    
    override var updatePrepare: ((OpaquePointer?, TemplateModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_text(statement, index, (model.name as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.sdkTag ? 1 : 0)
            index += 1
            var caseIds = ""
            if let jsonData = try? JSONEncoder().encode(model.caseIds),  let jsonString = String(data: jsonData, encoding: .utf8) {
                caseIds = jsonString
            }
            sqlite3_bind_text(statement, index, (caseIds as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.usage)
            index += 1
            sqlite3_bind_int64(statement, index, model.clipCount)
            index += 1
            sqlite3_bind_int64(statement, index, model.canReplaceClipCount)
            index += 1
            sqlite3_bind_text(statement, index, (model.previewUrl as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_text(statement, index, (model.coverUrl as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_text(statement, index, (model.downloadUrl as NSString).utf8String, -1, nil)
            index += 1
            sqlite3_bind_int64(statement, index, model.id)
        }
    }
    
    override var selectPrepare: ((OpaquePointer?) -> TemplateModel) {
        { statement in
            var index: Int32 = 0
            let id = sqlite3_column_int64(statement, index)
            index += 1
            let name = String(cString: sqlite3_column_text(statement, index))
            index += 1
            let sdkTag = sqlite3_column_int64(statement, index) == 1
            index += 1
            let jsonString = String(cString: sqlite3_column_text(statement, index))
            var caseIds = [Int64]()
            if let jsonData = jsonString.data(using: .utf8) {
                do {
                    caseIds = try JSONDecoder().decode([Int64].self, from: jsonData)
                } catch {
                    print("Error decoding JSON to array: \(error)")
                }
            }
            index += 1
            let usage = sqlite3_column_int64(statement, index)
            index += 1
            let clipCount = sqlite3_column_int64(statement, index)
            index += 1
            let canReplaceClipCount = sqlite3_column_int64(statement, index)
            index += 1
            var previewUrl = ""
            if let cString = sqlite3_column_text(statement, index) {
                previewUrl = String(cString: cString)
            }
            index += 1
            var coverUrl = ""
            if let cString = sqlite3_column_text(statement, index) {
                coverUrl = String(cString: cString)
            }
            index += 1
            var downloadUrl = ""
            if let cString = sqlite3_column_text(statement, index) {
                downloadUrl = String(cString: cString)
            }
            
            
            let model = TemplateModel(id: id,
                                      name: name,
                                      sdkTag: sdkTag,
                                      usage: usage,
                                      clipCount: clipCount,
                                      canReplaceClipCount: canReplaceClipCount,
                                      previewUrl: previewUrl,
                                      coverUrl: coverUrl,
                                      downloadUrl: downloadUrl,
                                      caseIds: caseIds)
            return model
        }
    }
}
