//
//  ResultModel.swift
//  Probe
//
//  Created by Archie You on 2023/6/29.
//

import Cocoa
import Combine

class ResultModel: NSObject & DatabaseModelProtocol {
    enum State: Int64 {
        case ready = 0
        case inProgress = 1
        case success = 2
        case failed = 3
        
        var color: NSColor {
            switch self {
            case .ready:
                return .gray
            case .inProgress:
                return .blue
            case .success:
                return .green
            case .failed:
                return .red
            }
        }
    }
    
    var id: Int64
    var templateId: Int64
    var taskId: Int64
    
    @Published var state: State
    
    @Published var useMontage = false
    @Published var montageAbility = false
    @Published var montageAbilityFlag: String?
    
    @Published var startMemory: Int64
    @Published var endMemory: Int64
    @Published var maxMemory: Int64
    
    @Published var duration: Int64
    
    @Published var errorMsg: String?
    
    @Published var filePath: String?
    
    @Published var frameRenderingTimes = [FrameRenderingTimeModel]()
    
    init(id: Int64,
         templateId: Int64,
         taskId: Int64,
         state: State = .ready,
         useMontage: Bool = false,
         montageAbility: Bool = false,
         montageAbilityFlag: String? = nil,
         startMemory: Int64 = -1,
         endMemory: Int64 = -1,
         maxMemory: Int64 = -1,
         duration: Int64 = -1,
         errorMsg: String? = nil,
         filePath: String? = nil) {
        self.id = id
        self.templateId = templateId
        self.taskId = taskId
        self.state = state
        self.useMontage = useMontage
        self.montageAbility = montageAbility
        self.startMemory = startMemory
        self.endMemory = endMemory
        self.maxMemory = maxMemory
        self.duration = duration
        
        super.init()
        
        self.montageAbilityFlag = montageAbilityFlag
        self.errorMsg = errorMsg
        self.filePath = filePath
    }
    
    convenience init(templateId: Int64,
                     taskId: Int64,
                     state: State = .ready,
                     useMontage: Bool = false,
                     montageAbility: Bool = false,
                     montageAbilityFlag: String? = nil,
                     startMemory: Int64 = -1,
                     endMemory: Int64 = -1,
                     maxMemory: Int64 = -1,
                     duration: Int64 = -1,
                     errorMsg: String? = nil,
                     filePath: String? = nil) {
        let currentTime = Date().timeIntervalSince1970
        let id = Int64(currentTime * 1000000)
        self.init(id: id,
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
    }
}

extension ResultModel {
    var isFinished: Bool {
        self.state == .success || self.state == .failed
    }
    
    var longRenderingTimeFrameCount: Int {
        let longRenderingTimeFrames = frameRenderingTimes.filter {
            if $0.renderingTime > 100000 {
                return true
            }
            return false
        }
        return longRenderingTimeFrames.count
    }
}
