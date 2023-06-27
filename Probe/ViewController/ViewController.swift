//
//  ViewController.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/24.
//

import Cocoa
import RxSwift
import RxCocoa
import SnapKit

class ViewController: BaseViewController, SocketManagerDelegate, LaunchManagerDelegate, NSTableViewDelegate, NSTableViewDataSource {
    private let socketManager = SocketManager()
    private let launchManager = LaunchManager()
    private var templateModels: [TemplateModel] {
        AppContext.shared.caseManager.currentTestCase?.templateModels ?? []
    }
    private var needResendStartMessage = true
    
    @IBOutlet weak var headerContainerView: NSView!
    @IBOutlet weak var separator: NSView!
    @IBOutlet weak var tableContainerView: NSView!
    @IBOutlet weak var statisticsContainerView: NSView!
    @IBOutlet weak var controlContainerView: NSView!
    
    private lazy var headerViewController: HeaderViewController = {
        let vc = HeaderViewController()
        return vc
    }()
    private lazy var templateTableViewController: TemplateTableViewController = {
        let vc = TemplateTableViewController()
        return vc
    }()
    private lazy var statisticsViewController: StatisticsViewController = {
        let vc = StatisticsViewController()
        return vc
    }()
    private lazy var controlViewController: ControlViewController = {
        weak var weakSelf = self
        let vc = ControlViewController(socketManager: socketManager, launchManager: launchManager, sendStartMessage: {
            weakSelf?.sendStartMessage()
        })
        return vc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(headerViewController)
        headerContainerView.addSubview(headerViewController.view)
        headerViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        separator.wantsLayer = true
        separator.layer?.backgroundColor = NSColor.gray.cgColor
        
        addChild(templateTableViewController)
        tableContainerView.addSubview(templateTableViewController.view)
        templateTableViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        addChild(statisticsViewController)
        statisticsContainerView.addSubview(statisticsViewController.view)
        statisticsViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        addChild(controlViewController)
        controlContainerView.addSubview(controlViewController.view)
        controlViewController.view.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        socketManager.delegate = self
        launchManager.delegate = self

        AppContext.shared.caseManager.setup()
    }
    
    private func sendStartMessage() {
        guard needResendStartMessage else { return }
        needResendStartMessage = false
        socketManager.connectToServer()
        socketManager.sendStartMessage(templateModels.filter({ $0.state == .ready }))
    }
    
// MARK: - SocketManagerDelegate
    func onInProgress(_ message: [String : String]) {
        if let id = message["id"], let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.state = .inProgress
            caseManager.update(templateModel)
        }
    }
    
    func onUpdate(_ message: [String : String]) {
        if let id = message["id"], let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.name = message["name"] ?? "unknown"
            caseManager.update(templateModel)
        }
    }
    
    func onUseMontage(_ message: [String : String]) {
        if let id = message["id"],
           let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.useMontage = (message["useMontage"] as? NSString)?.boolValue ?? false
            templateModel.useMontageFlag = message["flag"]
            
            caseManager.update(templateModel, needSave: true)
        }
    }
    
    func onFinish(_ message: [String : String]) {
        if let id = message["id"],
           let success = (message["success"] as? NSString)?.boolValue,
           let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.state = success ? .success : .failed
            templateModel.startMemory = (message["startMemory"] as? NSString)?.integerValue ?? -1
            templateModel.endMemory = (message["endMemory"] as? NSString)?.integerValue ?? -1
            templateModel.maxMemory = (message["maxMemory"] as? NSString)?.integerValue ?? -1
            templateModel.duration = (message["duration"] as? NSString)?.integerValue ?? -1
            templateModel.errorMsg = message["error_msg"]
            templateModel.filePath = message["file_path"]
            
            caseManager.update(templateModel, needSave: true)
            
            if success {
                launchManager.sendDownloadMessage(templateModel)
            } else {
                socketManager.sendEndMessage()
            }
        }
    }
    
    func onConnect() {
        sendStartMessage()
    }
    
    func onDisconnect() {
        needResendStartMessage = true
        
        launchManager.sendLaunchMessage()
        let inProgressTemplateModels = templateModels.filter { $0.state == .inProgress }
        inProgressTemplateModels.forEach {
            $0.state = .failed
            $0.errorMsg = "crash"
            self.caseManager.update($0)
        }
    }
    
// MARK: - LaunchManagerDelegate
    func onDownloadFinished(_ templateId: String) {
        socketManager.sendEndMessage()
    }
}
