//
//  ViewController.swift
//  Probe
//
//  Created by 尤坤 on 2023/5/24.
//

import Cocoa
import RxSwift
import RxCocoa

class ViewController: NSViewController, SocketManagerDelegate, LaunchManagerDelegate, NSTableViewDelegate, NSTableViewDataSource {
    private var exportManager = ExportManager()
    private let socketManager = SocketManager()
    
    private lazy var databaseWrapper = {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let databaseURL = documentsURL.appendingPathComponent("database.db")
        return SQLiteDatabaseWrapper(databasePath: databaseURL.path)
    }()
    private lazy var cacheManager = CacheManager(database: databaseWrapper)
    
    private let launchManager = LaunchManager()
    private let caseManager = CaseManager()
    private var templateModels: [TemplateModel] {
        AppContext.shared.caseManager.currentTestCase?.templateModels ?? []
    }
    private var needResendStartMessage = true
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var successCountLabel: NSTextField!
    @IBOutlet weak var failedCountLabel: NSTextField!
    
    
    private var newCaseWindowController: NewCaseWindowController?
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        successCountLabel.textColor = TemplateModel.State.success.color
        failedCountLabel.textColor = TemplateModel.State.failed.color
        
        socketManager.delegate = self
        launchManager.delegate = self

        weak var weakSelf = self
        AppContext.shared.caseManager.currentTestCaseObservable.subscribe { _ in
            weakSelf?.update()
        }.disposed(by: disposeBag)
        
//        templateModels = cacheManager.select()
        update()
    }
    
    private func update() {
        tableView.reloadData()
        
        let totalCount = templateModels.count
        let finishedTemplateModels = templateModels.filter { $0.state == .failed || $0.state == .success }
        let finishedCount = finishedTemplateModels.count
        let successTemplateModels = finishedTemplateModels.filter { $0.state == .success }
        let successCount = successTemplateModels.count
        
        progressLabel.stringValue = "\(finishedCount)/\(totalCount)"
        successCountLabel.stringValue = "\(successCount)"
        failedCountLabel.stringValue = "\(finishedCount - successCount)"
    }
    
    private func sendStartMessage() {
        guard needResendStartMessage else { return }
        needResendStartMessage = false
        socketManager.connectToServer()
        socketManager.sendStartMessage(templateModels.filter({ $0.state == .ready }))
    }
    
// MARK: - IBAction
    @IBAction func onImport(_ sender: Any) {
        newCaseWindowController = NewCaseWindowController()
        newCaseWindowController?.window?.center()
        newCaseWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    @IBAction func onStart(_ sender: Any) {
        socketManager.connectToServer()
        sendStartMessage()
    }
    
    @IBAction func onExport(_ sender: Any) {
        exportManager.exprot(templateModels)
    }
    
    @IBAction func onExportFailedIds(_ sender: Any) {
        exportManager.exportFailedIds(templateModels)
    }
    
    @IBAction func onEnd(_ sender: Any) {
        launchManager.end()
    }
// MARK: - SocketManagerDelegate
    func onInProgress(_ message: [String : String]) {
        if let id = message["id"], let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.state = .inProgress
            update()
        }
    }
    
    func onUpdate(_ message: [String : String]) {
        if let id = message["id"], let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.name = message["name"] ?? "unknown"
            update()
        }
    }
    
    func onUseMontage(_ message: [String : String]) {
        if let id = message["id"],
           let templateModel = templateModels.first(where: { $0.id == id }) {
            templateModel.useMontage = (message["useMontage"] as? NSString)?.boolValue ?? false
            templateModel.useMontageFlag = message["flag"]
            
            cacheManager.update(templateModel)
            
            update()
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
            
            cacheManager.update(templateModel)
            
            if success {
                launchManager.download(templateModel)
            } else {
                socketManager.sendEndMessage()
            }
            
            update()
        }
    }
    
    func onConnect() {
        sendStartMessage()
    }
    
    func onDisconnect() {
        needResendStartMessage = true
        
        launchManager.launch()
        let inProgressTemplateModels = templateModels.filter { $0.state == .inProgress }
        inProgressTemplateModels.forEach {
            $0.state = .failed
            $0.errorMsg = "crash"
            cacheManager.update($0)
        }
        
        update()
    }
    
// MARK: - LaunchManagerDelegate
    func onDownloadFinished(_ templateId: String) {
        socketManager.sendEndMessage()
    }
    
// MARK: - NSTableViewDelegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        return templateModels.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TableCellView"), owner: nil) as? TableCellView
        view?.setup(templateModels[row])
        var frame = view?.frame
        frame?.size.width = tableView.frame.width
        if let frame = frame {
            view?.frame = frame
        }
        return view ?? TableCellView()
    }
}

