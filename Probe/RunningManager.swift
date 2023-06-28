//
//  RunningManager.swift
//  Probe
//
//  Created by Archie You on 2023/6/27.
//

import Cocoa

class RunningManager: NSObject, SocketManagerDelegate, LaunchManagerDelegate {
    private let socketManager = SocketManager()
    private let launchManager = LaunchManager()
    var caseManager: CaseManager {
        AppContext.shared.caseManager
    }
    
    private var needResendStartMessage = true
    
    private var isRuning = false
    private var isFinished: Bool {
        if let templateModels = runningTestCase?.templateModels {
            return !templateModels.contains {$0.state == .ready || $0.state == .inProgress}
        }
        return true
    }
    
    private var runningTestCase: TestCaseModel?
    
    override init() {
        super.init()
        
        socketManager.delegate = self
        launchManager.delegate = self
    }
    
    func start(_ testCase: TestCaseModel) {
        guard !isRuning else { return }
        
        isRuning = true
        needResendStartMessage = true
        
        runningTestCase = testCase
        
        launchManager.sendConfigMessage(testCase)
        socketManager.connectToServer()
        sendStartMessage()
    }
    
    func stop() {
        isRuning = false
        socketManager.disconnectToServer()
    }
    
    private func finish() {
        isRuning = false
        socketManager.disconnectToServer()
    }
    
    private func sendStartMessage() {
        guard needResendStartMessage,
              isRuning,
              !isFinished,
              let templateModels = runningTestCase?.templateModels
        else { return }
        
        needResendStartMessage = false
        let models = templateModels.filter{ $0.state == .ready }
        
        socketManager.connectToServer()
        socketManager.sendStartMessage(models)
    }
    
    // MARK: - SocketManagerDelegate
    func onInProgress(_ message: [String : String]) {
        if let id = message["id"], let templateModel = runningTestCase?.templateModels.first(where: { $0.id == id }) {
            templateModel.state = .inProgress
            caseManager.update(templateModel)
        }
    }
    
    func onUpdate(_ message: [String : String]) {
        if let id = message["id"], let templateModel = runningTestCase?.templateModels.first(where: { $0.id == id }) {
            templateModel.name = message["name"] ?? "unknown"
            caseManager.update(templateModel)
        }
    }
    
    func onUseMontage(_ message: [String : String]) {
        if let id = message["id"],
           let templateModel = runningTestCase?.templateModels.first(where: { $0.id == id }) {
            templateModel.useMontage = (message["useMontage"] as? NSString)?.boolValue ?? false
            templateModel.useMontageFlag = message["flag"]
            
            caseManager.update(templateModel, needSave: true)
        }
    }
    
    func onFrameRenderingTime(_ message: [String : String]) {
        if let id = message["id"],
           let templateModel = runningTestCase?.templateModels.first(where: { $0.id == id }) {
            if let frameRenderingTime = message["frameRenderingTime"]?.toJsonObject(){
                templateModel.frameRenderingTime.removeAll()
                for (key, value) in frameRenderingTime {
                    templateModel.frameRenderingTime[(key as NSString).longLongValue] = (value as NSString).longLongValue
                }
            }
            
            caseManager.update(templateModel, needSave: true)
        }
    }
    
    func onFinish(_ message: [String : String]) {
        if let id = message["id"],
           let success = (message["success"] as? NSString)?.boolValue,
           let templateModel = runningTestCase?.templateModels.first(where: { $0.id == id }) {
            templateModel.state = success ? .success : .failed
            templateModel.startMemory = (message["startMemory"] as? NSString)?.integerValue ?? -1
            templateModel.endMemory = (message["endMemory"] as? NSString)?.integerValue ?? -1
            templateModel.maxMemory = (message["maxMemory"] as? NSString)?.integerValue ?? -1
            templateModel.duration = (message["duration"] as? NSString)?.integerValue ?? -1
            templateModel.errorMsg = message["error_msg"]
            templateModel.filePath = message["file_path"]
            
            caseManager.update(templateModel, needSave: true)
            
            if isFinished {
                finish()
            }
            
            if success {
                launchManager.sendDownloadMessage(templateModel)
            } else {
                socketManager.sendEndMessage()
            }
        }
    }
    
    func onConnect() {
        guard isRuning else { return }
        sendStartMessage()
    }
    
    func onDisconnect() {
        guard isRuning else { return }
        needResendStartMessage = true
        
        if let inProgressTemplateModels = runningTestCase?.templateModels.filter({ $0.state == .inProgress }) {
            inProgressTemplateModels.forEach {
                $0.state = .failed
                $0.errorMsg = "crash"
                self.caseManager.update($0)
            }
        }
        
        if isFinished {
            finish()
        } else {
            launchManager.sendLaunchMessage()
        }
    }
    
    // MARK: - LaunchManagerDelegate
    func onDownloadFinished(_ templateId: String) {
        socketManager.sendEndMessage()
    }
}
