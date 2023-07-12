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
    
    private var task: RunningTaskModel?
    private var isRunning: Bool {
        return task?.isRunning ?? false
    }
    
    override init() {
        super.init()
        
        socketManager.delegate = self
        launchManager.delegate = self
    }
    
    func start(_ testCase: TestCaseModel) {
        let templates = testCase.templates.filter { !$0.isFinish(in: testCase) }
        start(testCase, templates)
    }
    
    func start(_ testCase: TestCaseModel, templateIndexs: [Int]) {
        let models = templateIndexs.map{ testCase.templates[$0] }
        start(testCase, models)
    }
    
    func start(_ testCase: TestCaseModel, _ templates: [TemplateModel]) {
        print("[Running]start(\(testCase.name),\(templates.count))")
        guard !isRunning else { return }
        
        needResendStartMessage = true
        
        let vidoOutputPath = AppContext.shared.fileManager.getVideoOutputPath(testCase)
        let config = RunningTaskConfig(vidoOutputPath: vidoOutputPath)
        
        let task = RunningTaskModel(caseId: testCase.id, config: config, templateIds: templates.map({ $0.id }))

        task.templates = templates
        
        task.update()
        
        caseManager.databaseManager.runningTaskTableManager.insert(task)
        
        testCase.runningTasks.append(task)
        caseManager.runningTasks.append(task)

        task.isRunning = true
        self.task = task
        
        launchManager.sendConfigMessage(config.vidoOutputPath)
        socketManager.connectToServer()
        sendStartMessage()
    }
    
    func stop() {
        print("[Running][\(task?.id ?? 0)]Stop")
        task?.isRunning = false
        socketManager.disconnectToServer()
    }
    
    private func finish() {
        print("[Running][\(task?.id ?? 0)]finish")
        task?.isRunning = false
        socketManager.disconnectToServer()
    }
    
    private func sendStartMessage() {
        print("[Running][\(task?.id ?? 0)]Try Send Start Message(needResendStartMessage:\(needResendStartMessage),isRunning:\(isRunning),isFinished:\(task?.isFinished ?? true))")
        guard needResendStartMessage,
              let task = task,
              isRunning,
              !task.isFinished
        else { return }
        
        needResendStartMessage = false

        let templates = task.templates.filter {
            !$0.results.contains {
                $0.taskId == task.id && $0.isFinished
            }
        }
        
        socketManager.sendStartMessage(templates)
    }
    
    // MARK: - SocketManagerDelegate
    func onInProgress(_ message: [String : String]) {
        if let id = (message["id"] as? NSString)?.longLongValue,
           let task = task,
           let result = caseManager.getResult(task.id, id) {
            result.state = .inProgress
            caseManager.databaseManager.resultTableManager.update(result)
        }
    }
    
    func onUpdate(_ message: [String : String]) {
        if let id = (message["id"] as? NSString)?.longLongValue,
           let task = task,
           let template = task.templates.first(where: { $0.id == id }) {
            template.name = message["name"] ?? "unknown"
            template.sdkTag = (message["sdk_tag"] as? NSString)?.boolValue ?? false
            template.usage = (message["show_c"] as? NSString)?.longLongValue ?? 0
            template.clipCount = (message["clip_count"] as? NSString)?.longLongValue ?? 0
            template.canReplaceClipCount = (message["can_replace_clip_count"] as? NSString)?.longLongValue ?? 0
            template.previewUrl = message["preview_url"] ?? ""
            template.coverUrl = message["cover"] ?? ""
            template.downloadUrl = message["download_url"] ?? ""
            caseManager.databaseManager.templateTableManager.update(template)
        }
    }
    
    func onMontageAbility(_ message: [String : String]) {
        if let id = (message["id"] as? NSString)?.longLongValue,
           let task = task,
           let result = caseManager.getResult(task.id, id) {
            result.montageAbility = (message["enable"] as? NSString)?.boolValue ?? false
            result.montageAbilityFlag = message["flag"]
            
            caseManager.databaseManager.resultTableManager.update(result)
        }
    }
    
    func onFrameRenderingTime(_ message: [String : String]) {
        if let id = (message["id"] as? NSString)?.longLongValue,
           let task = task,
           let result = caseManager.getResult(task.id, id) {
            if let frameRenderingTime = message["frameRenderingTime"]?.toJsonObject(){
                for (postition, renderingTime) in frameRenderingTime {
                    let model = FrameRenderingTimeModel(postition: (postition as NSString).longLongValue, renderingTime: (renderingTime as NSString).longLongValue, resultId: result.id)
                    caseManager.databaseManager.frameRenderingTimeTableManager.insert(model)
                    result.frameRenderingTimes.append(model)
                }
                caseManager.frameRenderingTimes += result.frameRenderingTimes
            }
        }
    }
    
    func onFinish(_ message: [String : String]) {
        if let id = (message["id"] as? NSString)?.longLongValue,
           let task = task,
           let result = caseManager.getResult(task.id, id),
           let success = (message["success"] as? NSString)?.boolValue {
            result.state = success ? .success : .failed
            result.useMontage = (message["useMontage"]  as? NSString)?.boolValue ?? false
            result.startMemory = (message["startMemory"] as? NSString)?.longLongValue ?? -1
            result.endMemory = (message["endMemory"] as? NSString)?.longLongValue ?? -1
            result.maxMemory = (message["maxMemory"] as? NSString)?.longLongValue ?? -1
            result.duration = (message["duration"] as? NSString)?.longLongValue ?? -1
            result.errorMsg = message["error_msg"]
            result.filePath = message["file_path"]
            
            caseManager.databaseManager.resultTableManager.update(result)
            
            if task.isFinished {
                finish()
            }
            
            if success {
                task.successCount += 1
            } else {
                task.failedCount += 1
            }
            task.finishedCount += 1
            
            if success, let filePath = result.filePath {
                launchManager.sendDownloadMessage(result.templateId, filePath: filePath)
            } else {
                socketManager.sendEndMessage()
            }
        }
    }
    
    func onConnect() {
        guard isRunning else { return }
        sendStartMessage()
    }
    
    func onDisconnect() {
        guard let task = task, isRunning else { return }
        needResendStartMessage = true
        
        let results = task.results.filter({ $0.state == .inProgress })
        for result in results {
            result.state = .failed
            result.errorMsg = "crash"
            caseManager.databaseManager.resultTableManager.update(result)
        }
        task.failedCount += results.count
        task.finishedCount += results.count
        
        if task.isFinished {
            finish()
        } else {
            launchManager.sendLaunchMessage()
        }
    }
    
    func onTimeout() {
        guard let task = task, isRunning else { return }
        
        let results = task.results.filter({ $0.state == .inProgress })
        for result in results {
            result.state = .failed
            result.errorMsg = "timeout"
            caseManager.databaseManager.resultTableManager.update(result)
        }
        task.failedCount += results.count
        task.finishedCount += results.count
        
        socketManager.sendEndMessage()
    }
    
    // MARK: - LaunchManagerDelegate
    func onDownloadFinished(_ templateId: String) {
        socketManager.sendEndMessage()
    }
}
