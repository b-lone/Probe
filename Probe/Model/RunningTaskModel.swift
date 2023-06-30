//
//  RunningTaskModel.swift
//  Probe
//
//  Created by Archie You on 2023/6/30.
//

import Cocoa
import Combine

class RunningTaskConfig: NSObject {
    let vidoOutputPath: String
    
    init(vidoOutputPath: String) {
        self.vidoOutputPath = vidoOutputPath
    }
}

class RunningTaskModel: NSObject & DatabaseModelProtocol {
    var id: Int64
    var caseId: Int64
    @Published var sum: Int = 0
    @Published var finishedCount: Int = 0
    @Published var successCount: Int = 0
    @Published var failedCount: Int = 0
    var isRunning = false
    
    var config: RunningTaskConfig
    
    var templateIds = [Int64]()
    var templates = [TemplateModel]()
    var results = [ResultModel]()
    
    init(id: Int64,
         caseId: Int64,
         config: RunningTaskConfig,
         templateIds: [Int64]) {
        self.id = id
        self.caseId = caseId
        self.config = config
        self.templateIds = templateIds
    }
    
    convenience init(caseId: Int64,
                     config: RunningTaskConfig,
                     templateIds: [Int64]) {
        let currentTime = Date().timeIntervalSince1970
        let id = Int64(currentTime * 1000)
        self.init(id: id,
                  caseId: caseId,
                  config: config,
                  templateIds: templateIds)
    }
    
}

extension RunningTaskModel {
    var isFinished: Bool {
        for template in templates {
            if let result = template.results.first(where: { $0.taskId == self.id }) {
                if !result.isFinished {
                    return false
                }
            } else {
                return false
            }
        }
        return true
    }
    
    func update() {
        sum = templates.count
        let finishedResults = templates.compactMap {
            if let result = $0.results.first(where: { $0.taskId == self.id })  {
                if result.isFinished {
                    return result
                }
            }
            return nil;
        }
        let successResults = finishedResults.filter { $0.state == .success }
        successCount = successResults.count
        let failedResults = finishedResults.filter { $0.state == .failed }
        failedCount = failedResults.count
        finishedCount = finishedResults.count
    }
}
