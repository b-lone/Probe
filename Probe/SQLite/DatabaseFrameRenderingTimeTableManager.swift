//
//  DatabaseFrameRenderingTimeTableManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/28.
//

import Cocoa
import SQLite3

class DatabaseFrameRenderingTimeTableManager: BaseDatabaseTableManager<FrameRenderingTimeModel> {
    private let positionColomnName = "position"
    private let renderingTimeColomnName = "rendering_time"
    private let resultIdColomnName = "result_id"
    private let templateIdColomnName = "template_id"
    
    init() {
        super.init(tableName: "frame_rendering_times")
    }
    
    override var createTableSQL: String {
        """
        CREATE TABLE IF NOT EXISTS \(tableName)
        (
        \(idColomnName) INTEGER PRIMARY KEY,
        \(positionColomnName) INTEGER,
        \(renderingTimeColomnName) INTEGER,
        \(resultIdColomnName) INTEGER
        )
        """
    }
    
    override var insertSQL: String {
        """
        INSERT INTO \(tableName)
        (
        \(idColomnName),
        \(positionColomnName),
        \(renderingTimeColomnName),
        \(resultIdColomnName)
        )
        VALUES
        (?, ?, ?, ?)
        """
    }
    override var insertPrepare: ((OpaquePointer?, FrameRenderingTimeModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.id)
            index += 1
            sqlite3_bind_int64(statement, index, model.postition)
            index += 1
            sqlite3_bind_int64(statement, index, model.renderingTime)
            index += 1
            sqlite3_bind_int64(statement, index, model.resultId)
        }
    }
    
    override var updateSQL: String {
        """
        UPDATE \(tableName)
        SET \(positionColomnName) = ?,
        \(renderingTimeColomnName) = ?,
        \(resultIdColomnName) = ?
        WHERE \(idColomnName) = ?
        """
    }
    
    override var updatePrepare: ((OpaquePointer?, FrameRenderingTimeModel) -> Void) {
        { statement, model in
            var index: Int32 = 1
            sqlite3_bind_int64(statement, index, model.postition)
            index += 1
            sqlite3_bind_int64(statement, index, model.renderingTime)
            index += 1
            sqlite3_bind_int64(statement, index, model.resultId)
            index += 1
            sqlite3_bind_int64(statement, index, model.id)
        }
    }
    
    override var selectPrepare: ((OpaquePointer?) -> FrameRenderingTimeModel) {
        { statement in
            var index: Int32 = 0
            let id = sqlite3_column_int64(statement, index)
            index += 1
            let postition = sqlite3_column_int64(statement, index)
            index += 1
            let renderingTime = sqlite3_column_int64(statement, index)
            index += 1
            let resultId = sqlite3_column_int64(statement, index)
            
            let model = FrameRenderingTimeModel(id: id, postition: postition, renderingTime: renderingTime, resultId: resultId)
            return model
        }
    }
}
